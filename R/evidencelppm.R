#'
#'   evidencelppm.R
#'
#'   spatialCovariateEvidence method for class lppm
#'
#'   $Revision: 1.10 $ $Date: 2023/05/02 07:56:12 $


spatialCovariateEvidence.lppm <- local({

  spatialCovariateEvidence.lppm <- function(model, covariate, ...,
                             lambdatype=c("cif", "trend", "intensity"),
                             eps=NULL, dimyx=NULL, xy=NULL,
                             rule.eps=c("adjust.eps",
                                        "grow.frame", "shrink.frame"),
                             delta=NULL, nd=NULL,
                             interpolate=TRUE,
                             jitter=TRUE, jitterfactor=1, 
                             modelname=NULL, covname=NULL,
                             dataname=NULL, subset=NULL, clip.predict=TRUE) {
    lambdatype <- match.arg(lambdatype)
    rule.eps <- match.arg(rule.eps)
    #' evaluate covariate values at data points and at pixels
    ispois <- is.poisson(model)
    csr <- ispois && is.stationary(model)
    #' arguments controlling resolution
    pixels.given <- !(is.null(eps) && is.null(dimyx) && is.null(xy))
    sampling.given <- !(is.null(delta) && is.null(nd))
    resolution.given <- pixels.given || sampling.given

    #' determine names
    if(is.null(modelname))
      modelname <- if(csr) "CSR" else short.deparse(substitute(model))
    if(is.null(covname)) {
      covname <- singlestring(short.deparse(substitute(covariate)))
      if(is.character(covariate)) covname <- covariate
    }
    if(is.null(dataname))
      dataname <- model$Xname
    info <-  list(modelname=modelname, covname=covname,
                  dataname=dataname, csr=csr, ispois=ispois, 
                  spacename="linear network")

    #' convert character covariate to function
    if(is.character(covariate)) {
      #' One of the characters 'x' or 'y'
      #' Turn it into a function.
      ns <- length(covariate)
      if(ns == 0) stop("covariate is empty")
      if(ns > 1) stop("more than one covariate specified")
      covname <- covariate
      covariate <- switch(covariate,
                          x=xcoordfun,
                          y=ycoordfun,
                          stop(paste("Unrecognised covariate",
                                     dQuote(covariate))))
    }
  
    #' extract model components
    X <- model$X
    fit <- model$fit
    #'
    L <- as.linnet(X)
    Q <- quad.ppm(fit)
    #' restrict to subset if required
    if(!is.null(subset)) {
      X <- X[subset]
      Q <- Q[subset]
    }
    isdat <- is.data(Q)
    U <- union.quad(Q)
    wt <- w.quad(Q)
  
    #' evaluate covariate
    if(!is.marked(model)) {
      #' ...................  unmarked .......................
      if(is.im(covariate)) {
        if(is.linim(covariate)) {
          type <- "linim"
          Zimage <- covariate
          if(resolution.given) Zimage <- as.linim(Zimage,
                                                  eps=eps, dimyx=dimyx, xy=xy,
                                                  rule.eps=rule.eps,
                                                  delta=delta, nd=nd)
        } else {
          type <- "im"
          Zimage <- as.linim(covariate, L,
                             eps=eps, dimyx=dimyx, xy=xy,
                             rule.eps=rule.eps,
                             delta=delta, nd=nd)
        }
        if(!interpolate) {
          #' look up covariate values at quadrature points
          Zvalues <- safelookup(covariate, U)
        } else {
          #' evaluate at quadrature points by interpolation
          Zvalues <- interp.im(covariate, U$x, U$y)
          #' fix boundary glitches
          if(any(uhoh <- is.na(Zvalues)))
            Zvalues[uhoh] <- safelookup(covariate, U[uhoh])
        }
        #' extract data values
        ZX <- Zvalues[isdat]
      } else if(is.function(covariate)) {
        type <- "function"
        Zimage <- as.linim(covariate, L,
                           eps=eps, dimyx=dimyx, xy=xy,
                           rule.eps=rule.eps,
                           delta=delta, nd=nd)
        #' evaluate exactly at quadrature points
        Zvalues <- covariate(U$x, U$y)
        if(!all(is.finite(Zvalues)))
          warning("covariate function returned NA or Inf values")
        #' extract data values
        ZX <- Zvalues[isdat]
        #' collapse function body to single string
        covname <- singlestring(covname)
      } else if(is.null(covariate)) {
        stop("The covariate is NULL", call.=FALSE)
      } else stop(paste("The covariate should be",
                        "an image, a function(x,y)",
                        "or one of the characters",
                        sQuote("x"), "or", sQuote("y")),
                  call.=FALSE)
      #' corresponding fitted [conditional] intensity values
      lambda <- as.vector(predict(model, locations=U, type=lambdatype))
    } else {
      #' ...................  marked .......................
      if(!is.multitype(model))
        stop("Only implemented for multitype models (factor marks)")
      marx <- marks(U, dfok=FALSE)
      possmarks <- levels(marx)
      #' single image: replicate 
      if(is.im(covariate)) {
        covariate <- rep(list(covariate), length(possmarks))
        names(covariate) <- possmarks
      }
      #'
      if(is.list(covariate) && all(sapply(covariate, is.im))) {
        #' list of images
        if(length(covariate) != length(possmarks))
          stop("Number of images does not match number of possible marks")
        #' determine type of data
        islinim <- sapply(covariate, is.linim)
        type <- if(all(islinim)) "linim" else "im"
        Zimage <- as.solist(covariate)
        #' convert 2D pixel images to 'linim'
        Zimage[!islinim] <- lapply(Zimage[!islinim], as.linim, L=L,
                                   eps=eps, dimyx=dimyx, xy=xy,
                                   rule.eps=rule.eps,
                                   delta=delta, nd=nd)
        if(resolution.given) 
          Zimage[islinim] <- lapply(Zimage[!islinim], as.linim,
                                   eps=eps, dimyx=dimyx, xy=xy,
                                   rule.eps=rule.eps,
                                   delta=delta, nd=nd)
        #' evaluate covariate at each data point by interpolation
        Zvalues <- numeric(npoints(U))
        for(k in seq_along(possmarks)) {
          ii <- (marx == possmarks[k])
          covariate.k <- covariate[[k]]
          if(!interpolate) {
            #' direct lookup
            values <- safelookup(covariate.k, U[ii])
          } else {
            #' interpolation
            values <- interp.im(covariate.k, x=U$x[ii], y=U$y[ii])
            #' fix boundary glitches
            if(any(uhoh <- is.na(values)))
              values[uhoh] <- safelookup(covariate.k, U[ii][uhoh])
          }
          Zvalues[ii] <- values
        }
        #' extract data values
        ZX <- Zvalues[isdat]
        #' corresponding fitted [conditional] intensity values
        lambda <- predict(model, locations=U, type=lambdatype)
        if(length(lambda) != length(Zvalues))
          stop("Internal error: length(lambda) != length(Zvalues)")
      } else if(is.function(covariate)) {
        type <- "function"
        #' evaluate exactly at quadrature points
        Zvalues <- functioncaller(x=U$x, y=U$y, m=marx, f=covariate, ...)
        #' functioncaller: function(x,y,m,f,...) { f(x,y,m,...) }
        #' extract data values
        ZX <- Zvalues[isdat]
        #' corresponding fitted [conditional] intensity values
        lambda <- predict(model, locations=U, type=lambdatype)
        if(length(lambda) != length(Zvalues))
          stop("Internal error: length(lambda) != length(Zvalues)")
        #' images
        Zimage <- list()
        for(k in seq_along(possmarks))
          Zimage[[k]] <- as.linim(functioncaller, L=L, m=possmarks[k],
                                  f=covariate,
                                  eps=eps, dimyx=dimyx, xy=xy,
                                  rule.eps=rule.eps,
                                  delta=delta, nd=nd)
        #' collapse function body to single string
        covname <- singlestring(covname)
      } else if(is.null(covariate)) {
        stop("The covariate is NULL", call.=FALSE)
      } else stop(paste("For a multitype point process model,",
                        "the covariate should be an image, a list of images,",
                        "a function(x,y,m)", 
                        "or one of the characters",
                        sQuote("x"), "or", sQuote("y")),
                  call.=FALSE)
    }    
    #' ..........................................................

    #' apply jittering to avoid ties
    if(jitter) {
      ZX <- jitter(ZX, factor=jitterfactor)
      Zvalues <- jitter(Zvalues, factor=jitterfactor)
    }

    lambdaname <- if(is.poisson(model)) "intensity" else lambdatype
    lambdaname <- paste("the fitted", lambdaname)
    check.finite(lambda, xname=lambdaname, usergiven=FALSE)
    check.finite(Zvalues, xname="the covariate", usergiven=TRUE)

    #' lambda values at data points
    lambdaX <- predict(model, locations=X, type=lambdatype)

    #' lambda image(s)
    lambdaimage <- predict(model, type=lambdatype)
    
    #' restrict image to subset 
    if(clip.predict && !is.null(subset)) {
      Zimage      <- applySubset(Zimage, subset)
      lambdaimage <- applySubset(lambdaimage, subset)
    }

    #' wrap up 
    values <- list(Zimage      = Zimage,
                   lambdaimage = lambdaimage,
                   Zvalues     = Zvalues,
                   lambda      = lambda,
                   lambdaX     = lambdaX,
                   weights     = wt,
                   ZX          = ZX,
                   type        = type)
    return(list(values=values, info=info, X=X))
  }

  xcoordfun <- function(x,y,m){x}
  ycoordfun <- function(x,y,m){y}

  functioncaller <- function(x,y,m,f,...) {
    nf <- length(names(formals(f)))
    if(nf < 2) stop("Covariate function must have at least 2 arguments")
    value <- if(nf == 2) f(x,y) else if(nf == 3) f(x,y,m) else f(x,y,m,...)
    return(value)
  }

  applySubset <- function(X, subset) {
    if(is.im(X)) return(X[subset, drop=FALSE])
    if(is.imlist(X)) return(solapply(X, "[", i=subset, drop=FALSE))
    return(NULL)
  }
  spatialCovariateEvidence.lppm
})

