#
# linearK
#
# $Revision: 1.65 $ $Date: 2023/02/28 01:55:41 $
#
# K function for point pattern on linear network
#
#
linearK <- function(X, r=NULL, ..., correction="Ang", ratio=FALSE) {
  stopifnot(inherits(X, "lpp"))
  correction <- pickoption("correction", correction,
                           c(none="none",
                             Ang="Ang",
                             best="Ang"),
                           multi=FALSE)
  np <- npoints(X)
  lengthL <- volume(domain(X))
  samplesize <- npairs <- np * (np - 1)
  denom <- npairs/lengthL
  K <- linearKengine(X, r=r, ..., 
 		     denom=denom, samplesize=samplesize,
                     correction=correction, ratio=ratio)
  correction <- attr(K, "correction")
  # set appropriate y axis label
  switch(correction,
         Ang  = {
           ylab <- quote(K[L](r))
           fname <- c("K", "L")
         },
         none = {
           ylab <- quote(K[net](r))
           fname <- c("K", "net")
         })
  K <- rebadge.fv(K, new.ylab=ylab, new.fname=fname)
  attr(K, "correction") <- correction
  return(K)
}

linearKinhom <- function(X, lambda=NULL, r=NULL,  ...,
                         correction="Ang", normalise=TRUE, normpower=1,
			 update=TRUE, leaveoneout=TRUE, sigma=NULL,
			 ratio=FALSE) {
  stopifnot(inherits(X, "lpp"))
  loo.given <- !missing(leaveoneout)
  correction <- pickoption("correction", correction,
                           c(none="none",
                             Ang="Ang",
                             best="Ang"),
                           multi=FALSE)
  if(is.null(lambda)) 
    warn.once("linearKinhomNULL",
              "In linearKinhom the interpretation of 'lambda=NULL'",
              "has changed (in spatstat.linnet 3.1 and later);",
              "the function linearK is no longer invoked;",
              "instead the intensity lambda is estimated by kernel smoothing")

  if(normalise) {
    check.1.real(normpower)
    stopifnot(normpower >= 1)
  }
  lambdaX <- resolve.lambda.lpp(X, lambda, ...,
                                update=update, leaveoneout=leaveoneout,
                                loo.given=loo.given,
                                sigma=sigma,
                                lambdaname="lambda")
  invlam <- 1/lambdaX
  invlam2 <- outer(invlam, invlam, "*")
  lengthL <- volume(domain(X))
  denom <- if(!normalise) lengthL else
           if(normpower == 1) sum(invlam) else
           lengthL * (sum(invlam)/lengthL)^normpower

  K <- linearKengine(X,
                     reweight=invlam2, denom=denom, 
  	             r=r, correction=correction, 
	 	     ratio=ratio, ...)
  
  # set appropriate y axis label
  correction <- attr(K, "correction")
  switch(correction,
         Ang  = {
           ylab <- quote(K[L, inhom](r))
           yexp <- quote(K[list(L, "inhom")](r))
           fname <- c("K", "list(L, inhom)")
         },
         none = {
           ylab <- quote(K[net, inhom](r))
           yexp <- quote(K[list(net, "inhom")](r))
           fname <- c("K", "list(net, inhom)")
         })
  K <- rebadge.fv(K, new.fname=fname, new.ylab=ylab, new.yexp=yexp)
  attr(K, "correction") <- correction
  attr(K, "dangerous") <- attr(lambdaX, "dangerous")
  return(K)
}


resolve.lambda.lpp <- function(X, lambda, subset=NULL, ...,
                               update=TRUE, leaveoneout=TRUE,
                               everywhere=FALSE,
                               loo.given=TRUE,
                               sigma=NULL,
                               lambdaname) {
  if(missing(lambdaname)) lambdaname <- short.deparse(substitute(lambda))
  Y <- if(is.null(subset)) X else X[subset]
  danger <- TRUE
  if(is.null(lambda)) {
    ## compute a kernel density estimate at X
    lambdaX <- density(X, sigma=sigma, ..., at="points",
                       leaveoneout=leaveoneout)
    ## ensure it is positive
    lambdaX <- pmax(lambdaX, .Machine$double.eps)
    ## Restrict if required
    lambdaY <- if(is.null(subset)) lambdaX else lambdaX[subset]
    ## Compute at all locations if required
    if(everywhere)
      everylambda <- density(X, sigma=sigma, ..., at="pixels") 
  } else if(is.ppm(lambda) || is.lppm(lambda)) {
    ## fitted model
    model <- lambda
    if(update) {
      ## refit the model to the full dataset X
      model <- if(is.lppm(model)) update(model, X) else update(model, as.ppp(X))
      danger <- FALSE
      ## Now evaluate at data points
      lambdaX <- fitted(model, dataonly=TRUE, leaveoneout=leaveoneout)
      ## Restrict if required
      lambdaY <- if(is.null(subset)) lambdaX else lambdaX[subset]
      ## 
    } else {
      if(loo.given && leaveoneout)
        stop("leave-one-out calculation for fitted models is only available when update=TRUE",
             call.=FALSE)
      lambdaY <- predict(model, locations=as.data.frame(as.ppp(Y)))
    }
    ## Also predict everywhere if desired
    if(everywhere) everylambda <- predict(model)
  } else {
    ## lambda is some other kind of object
    lambdaY <-
      if(is.vector(lambda)) lambda  else
      if(inherits(lambda, "linfun")) lambda(Y, ...) else
      if(inherits(lambda, "linim")) lambda[Y, drop=FALSE] else
      if(is.function(lambda)) {
        coo <- coords(Y)
        do.call.matched(lambda, list(x=coo$x, y=coo$y, ...))
      } else if(is.im(lambda)) safelookup(lambda, as.ppp(Y)) else 
      stop(paste(lambdaname, "should be",
                 "a numeric vector, function, pixel image, or fitted model"))
    if(everywhere) {
      L <- domain(X)
      everylambda <-
        if(inherits(lambda, "linim")) lambda else
        if(inherits(lambda, "linfun")) as.linim(lambda, L, ...) else
        if(is.function(lambda)) as.linim(lambda, L, ...) else
        if(is.im(lambda)) as.linim(lambda, L, ...) else NULL
    }
  }
  if(!is.numeric(lambdaY))
    stop(paste("Values of", lambdaname, "are not numeric"))
  if((nv <- length(lambdaY)) != (np <- npoints(Y)))
    stop(paste("Obtained", nv, "values of", lambdaname,
	   "but point pattern contains", np, "points"))
  if(any(lambdaY < 0))
    stop(paste("Negative values of", lambdaname, "obtained"))
  if(any(lambdaY == 0))
    stop(paste("Zero values of", lambdaname, "obtained"))
  if(danger)
    attr(lambdaY, "dangerous") <- lambdaname
  if(everywhere) return(list(lambdaX=lambdaY, lambdaImage=everylambda))
  return(lambdaY)
}

linearKengine <- function(X, ..., r=NULL, reweight=NULL,
                          denom=1, samplesize=NULL,
                          correction="Ang", ratio=FALSE, showworking=FALSE) {
  # ensure distance information is present
  X <- as.lpp(X, sparse=FALSE)
  # extract info about pattern
  np <- npoints(X)
  # extract linear network
  L <- domain(X)
  W <- Window(L)
  # determine r values
  rmaxdefault <- 0.98 * boundingradius(L)
  breaks <- handle.r.b.args(r, NULL, W, rmaxdefault=rmaxdefault)
  r <- breaks$r
  rmax <- breaks$max
  #
  type <- if(correction == "Ang") "L" else "net"
  fname <- c("K", type)
  ylab <- substitute(K[type](r), list(type=type))
  #
  if(np < 2) {
    # no pairs to count: return zero function
    zeroes <- numeric(length(r))
    df <- data.frame(r = r, est = zeroes)
    K <- ratfv(df, NULL, 0,
            "r", ylab,
            "est", . ~ r, c(0, rmax),
            c("r", makefvlabel(NULL, "hat", fname)), 
            c("distance argument r", "estimated %s"),
            fname = fname,
	    ratio=ratio)
    unitname(K) <- unitname(X)
    if(correction == "Ang") {
      # tack on theoretical value
      K <- bind.ratfv(K,
		      quotient    = data.frame(theo=r), 
                      denominator = 0,
                      labl = makefvlabel(NULL, NULL, fname, "theo"),
                      desc = "theoretical Poisson %s",
		      ratio = ratio)
    }
    attr(K, "correction") <- correction
    return(K)
  }
  # compute pairwise distances  
  D <- pairdist(X)
  #---  compile into K function ---
  if(correction == "none" && is.null(reweight)) {
    # no weights (Okabe-Yamada)
    K <- compileK(D, r, denom=denom, fname=fname, ratio=ratio,
                  samplesize=samplesize)
    K <- rebadge.fv(K, ylab, fname)
    unitname(K) <- unitname(X)
    attr(K, "correction") <- correction
    return(K)
  }
  if(correction == "none") {
    edgewt <- 1
  } else {
    ## inverse m weights (Wei's correction)
    ## determine tolerance
    toler <- default.linnet.tolerance(L)
    ## compute m[i,j]
    m <- DoCountEnds(X, D, toler)
    edgewt <- 1/m
  }
  # compute K
  wt <- if(!is.null(reweight)) edgewt * reweight else edgewt
  K <- compileK(D, r, weights=wt, denom=denom, fname=fname, ratio=ratio,
                samplesize=samplesize)
  # tack on theoretical value
  if(ratio) {
    K <- bind.ratfv(K,
		    quotient = data.frame(theo = r),
		    denominator = samplesize %orifnull% denom,
                    labl = makefvlabel(NULL, NULL, fname, "theo"),
                    desc = "theoretical Poisson %s")
  } else {
    K <- bind.fv(K, data.frame(theo=r),
                 makefvlabel(NULL, NULL, fname, "theo"),
                 "theoretical Poisson %s")
  }		 
  K <- rebadge.fv(K, ylab, fname)
  unitname(K) <- unitname(X)
  fvnames(K, ".") <- rev(fvnames(K, "."))
  # show working
  if(showworking)
    attr(K, "working") <- list(D=D, wt=wt)
  attr(K, "correction") <- correction
  return(K)
}

ApplyConnected <- function(X, Engine, r=NULL,
                           ..., rule, auxdata=NULL) {
  # Apply 'Engine' to each connected component of domain(X)
  stopifnot(is.function(rule))
  # Ensure distance information is present
  X <- as.lpp(X, sparse=FALSE)
  L <- domain(X)
  # check network connectivity
  br <- boundingradius(L)
  if(disco <- is.infinite(br)) {
    # disconnected network
    XX <- connected(X)
    LL <- lapply(XX, domain)
    br <- max(sapply(LL, boundingradius))
  } else XX <- NULL
  # determine r values
  rmaxdefault <- 0.98 * br
  breaks <- handle.r.b.args(r, NULL, Window(L), rmaxdefault=rmaxdefault)
  r <- breaks$r
  if(!disco) {
    # single connected network
    stuff <- rule(X=X, auxdata=auxdata, ...)
    result <- do.call(Engine, append(list(X=X, r=r), stuff))
    return(result)
  }
  # disconnected network
  nsub <- length(XX)
  results <- anylist()
  denoms <- numeric(nsub)
  for(i in seq_len(nsub)) {
    X.i <- XX[[i]]
    sub.i <- attr(X.i, "retainpoints") # identifies which points of X
    aux.i <- if(length(auxdata) == 0) NULL else
             lapply(auxdata, marksubset, index=sub.i)
    stuff.i <- rule(X=X.i, auxdata=aux.i, ...)
    denoms[i] <- stuff.i$denom %orifnull% 1
    results[[i]] <- do.call(Engine, append(list(X=X.i, r=r), stuff.i))
  }
  result <- do.call(pool, append(results,
                                 list(weights=denoms,
				      relabel=FALSE, variance=FALSE)))
  return(result)
}

DoCountEnds <- function(X, D, toler) {
  stopifnot(is.lpp(X))
  stopifnot(is.matrix(D))
  nX <- npoints(X)
  if(nrow(D) != nX) stopifnot(nrow(D) == npoints(X))
  if(ncol(D) != nX) stopifnot(ncol(D) == npoints(X))
  m <- matrix(1, nX, nX)
  easy <- list(is.connected=TRUE)
  L <- domain(X)
  if(is.connected(L)) {
    ## network is connected
    for(j in 1:nX) {
      m[ -j, j] <- countends(L, X[-j], D[-j,j], toler=toler, internal=easy)
    }
  } else {
    ## network is disconnected - split into components
    vlab <- connected(L, what="labels")
    subsets <- split(seq_len(nvertices(L)), factor(vlab))
    for(subi in subsets) {
      ## extract one component and the points falling in it
      Xsubi <- thinNetwork(X, retainvertices=subi)
      ni <- npoints(Xsubi)
      if(ni >= 2) {
        Lsubi <- domain(Xsubi)
        ## identify which points of X are involved
        imap <- which(attr(Xsubi, "retainpoints"))
        ## handle
        for(j in seq_len(ni)) {
          ij <- imap[j]
          i.j <- imap[-j]
          m[ i.j, ij ] <- countends(Lsubi, Xsubi[-j], D[i.j, ij],
                                    toler=toler,
                                    internal=easy)
        }
      }
    }
  }
  if(any(uhoh <- (m == 0) & is.finite(D))) {
    warning("Internal error: disc boundary count equal to zero")
    m[uhoh] <- 1
  }
  return(m)
}

