#
# linearpcf.R
#
# $Revision: 1.32 $ $Date: 2023/03/10 03:51:30 $
#
# pair correlation function for point pattern on linear network
#
#
linearpcf <- function(X, r=NULL, ..., correction="Ang", ratio=FALSE) {
  stopifnot(inherits(X, "lpp"))
  correction <- pickoption("correction", correction,
                           c(none="none",
                             Ang="Ang",
                             best="Ang"),
                           multi=FALSE)
  # extract info about pattern
  np <- npoints(X)
  lengthL <- volume(domain(X))
  # compute
  samplesize <- npairs <- np * (np - 1)
  denom <- npairs/lengthL
  g <- linearpcfengine(X, r=r, ...,
                       denom=denom, correction=correction, ratio=ratio,
                       samplesize=samplesize)
  # extract bandwidth
  bw <- attr(g, "bw")
  correction <- attr(g, "correction") 
  # set appropriate y axis label
  switch(correction,
         Ang  = {
           ylab <- quote(g[L](r))
           fname <- c("g", "L")
         },
         none = {
           ylab <- quote(g[net](r))
           fname <- c("g", "net")
         })
  g <- rebadge.fv(g, new.ylab=ylab, new.fname=fname)
  # reattach bandwidth
  attr(g, "bw") <- bw
  attr(g, "correction") <- correction
  return(g)
}

linearpcfinhom <- function(X, lambda=NULL, r=NULL,  ...,
                           correction="Ang", normalise=TRUE, normpower=1,
			   update=TRUE, leaveoneout=TRUE,
                           sigma=NULL, adjust.sigma=1,
                           bw="nrd0", adjust.bw=1, ratio=FALSE) {
  stopifnot(inherits(X, "lpp"))
  loo.given <- !missing(leaveoneout)
  correction <- pickoption("correction", correction,
                           c(none="none",
                             Ang="Ang",
                             best="Ang"),
                           multi=FALSE)
  if(is.null(lambda)) 
    warn.once("linearpcfinhomNULL",
              "In linearpcfinhom the interpretation of 'lambda=NULL'",
              "has changed (in spatstat.linnet 3.1 and later);",
              "the function linearpcf is no longer invoked;",
              "instead the intensity lambda is estimated by kernel smoothing")

  if(normalise) {
    check.1.real(normpower)
    stopifnot(normpower >= 1)
  }
  # extract info about pattern
  lengthL <- volume(domain(X))
  #
  lambdaX <- resolve.lambda.lpp(X, lambda,
                                update=update,
                                leaveoneout=leaveoneout,
                                loo.given=loo.given,
                                sigma=sigma,
                                lambdaname="lambda",
                                adjust=adjust.sigma)
  #
  invlam <- 1/lambdaX
  invlam2 <- outer(invlam, invlam, "*")
  denom <- if(!normalise) lengthL else
           if(normpower == 1) sum(invlam) else
           lengthL * (sum(invlam)/lengthL)^normpower
  g <- linearpcfengine(X, ..., r=r, 
                       reweight=invlam2, denom=denom,
		       correction=correction,
                       bw=bw, adjust=adjust.bw,
                       ratio=ratio)
  # extract bandwidth
  bw <- attr(g, "bw")
  correction <- attr(g, "correction") 
  # set appropriate y axis label
  switch(correction,
         Ang  = {
           ylab <- quote(g[L, inhom](r))
           fname <- c("g", "list(L, inhom)")
         },
         none = {
           ylab <- quote(g[net, inhom](r))
           fname <- c("g", "list(net, inhom)")
         })
  g <- rebadge.fv(g, new.fname=fname, new.ylab=ylab)
  # reattach bandwidth
  attr(g, "bw") <- bw
  attr(g, "correction") <- correction
  attr(g, "dangerous") <- attr(lambdaX, "dangerous")
  return(g)
}


linearpcfengine <- function(X, ..., r=NULL,
                            reweight=NULL,
                            denom=1, samplesize=NULL,
			    correction="Ang", ratio=FALSE) {
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
  fname <- c("g", type)
  ylab <- substitute(g[type](r), list(type=type))
  #  
  if(np < 2) {
    # no pairs to count: return zero function
    zeroes <- numeric(length(r))
    df <- data.frame(r = r, est = zeroes)
    g <- ratfv(df, NULL, 0,
            "r", ylab,
            "est", . ~ r, c(0, rmax),
            c("r", makefvlabel(NULL, "hat", fname)), 
            c("distance argument r", "estimated %s"),
            fname = fname,
	    ratio=ratio)
    if(correction == "Ang") {
      # tack on theoretical value
      g <- bind.ratfv(g,
                      quotient = data.frame(theo=r),
		      denominator = 0, 
                      labl = makefvlabel(NULL, NULL, fname, "theo"),
                      desc = "theoretical Poisson %s",
   		      ratio=ratio)
    }
    attr(g, "correction") <- correction
    return(g)
  }
  # compute pairwise distances  
  D <- pairdist(X)
  #---  compile into pcf ---
  if(correction == "none" && is.null(reweight)) {
    # no weights (Okabe-Yamada)
    g <- compilepcf(D, r, denom=denom, fname=fname, ratio=ratio,
                    samplesize=samplesize)
    unitname(g) <- unitname(X)
    attr(g, "correction") <- correction
    return(g)
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
  # compute pcf
  wt <- if(!is.null(reweight)) edgewt * reweight else edgewt
  g <- compilepcf(D, r, weights=wt, denom=denom, ..., fname=fname, ratio=ratio,
                  samplesize=samplesize)
  # extract bandwidth
  bw <- attr(g, "bw")
  # tack on theoretical value
  g <- bind.ratfv(g,
                  quotient = data.frame(theo=rep.int(1,length(r))),
		  denominator = samplesize %orifnull% denom,
                  labl = makefvlabel(NULL, NULL, fname, "pois"),
                  desc = "theoretical Poisson %s",
		  ratio = ratio)
  # tweak
  unitname(g) <- unitname(X)
  fvnames(g, ".") <- rev(fvnames(g, "."))
  # tack on bandwidth again
  attr(g, "bw") <- bw
  attr(g, "correction") <- correction
  return(g)
}

