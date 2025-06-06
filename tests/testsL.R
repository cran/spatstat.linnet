#'
#'   Header for all (concatenated) test files
#'
#'   Require spatstat.linnet
#'   Obtain environment variable controlling tests.
#'
#'   $Revision: 1.5 $ $Date: 2020/04/30 05:31:37 $

require(spatstat.linnet)
FULLTEST <- (nchar(Sys.getenv("SPATSTAT_TEST", unset="")) > 0)
ALWAYS   <- TRUE
cat(paste("--------- Executing",
          if(FULLTEST) "** ALL **" else "**RESTRICTED** subset of",
          "test code -----------\n"))
#
# tests/lppstuff.R
#
# Tests for lpp code
#
#  $Revision: 1.74 $  $Date: 2025/01/18 03:44:09 $


local({
  if(ALWAYS) {
    #' make test data
    Xsimple <- runiflpp(6, simplenet)
    Xchic   <- chicago[c(TRUE, FALSE)]
    Xspid   <- spiders[c(TRUE, FALSE)]
    Xdend   <- dendrite[seq_len(npoints(dendrite)) %% 8 == 0]
  }
  
  if(FULLTEST) {
    #' lpp class support
    Xone <- Xsimple %mark% runif(6)
    Xtwo <- Xsimple %mark% data.frame(a=1:6, b=runif(6))
    print(summary(Xone))
    print(summary(Xtwo))
    plot(Xsimple, show.window=TRUE)
    plot(Xone)
    plot(Xtwo, do.several=FALSE)
    #' geometry etc
    rotate(Xsimple, pi/3, centre=c(0.2,0.3))
    superimpose.lpp(L=simplenet)
    W <- Window(Xsimple)
    #' cut.lpp
    tes <- lineardirichlet(Xsimple[1:4])
    f <- as.linfun(tes)
    Z <- as.linim(f)
    cut(Xsimple, tes)
    cut(Xsimple, f)
    cut(Xsimple, Z)

    #' check 'normalise' option in linearKinhom
    fit <- lppm(Xsimple ~x)
    K <- linearKinhom(Xsimple, lambda=fit, normalise=FALSE, leaveoneout=FALSE)
    plot(K)
    g <- linearpcfinhom(Xsimple, lambda=fit, normalise=FALSE, leaveoneout=FALSE)
    plot(g)
    K <- linearKinhom(Xsimple, lambda=fit, normalise=TRUE, leaveoneout=FALSE)
    plot(K)
    g <- linearpcfinhom(Xsimple, lambda=fit, normalise=TRUE, leaveoneout=FALSE)
    plot(g)
    ## other code blocks
    K <- linearKinhom(Xsimple, lambda=fit, correction="none", ratio=TRUE)
    g <- linearpcf(Xsimple, correction="none", ratio=TRUE)
    g1 <- linearpcf(Xsimple[1], ratio=TRUE)
    K1 <- linearKcross(dendrite[1], "thin", "thin", ratio=TRUE)
    ## check empty patterns OK
    X0 <- runiflpp(0, simplenet)
    print(X0)
    g <- linearpcf(X0, ratio=TRUE)
  }
  
  ## nearest neighbour distances
  eps <- sqrt(.Machine$double.eps)
  f <- function(mat,k) { apply(mat, 1, function(z,n) { sort(z)[n]  }, n=k+1) }
  g <- function(mat,k) { apply(mat, 1, function(z,n) { order(z)[n] }, n=k+1) }

  if(ALWAYS) {
    nn <- nndist(Xspid)
    nnP <- f(pairdist(Xspid), 1)
    if(any(abs(nn - nnP) > eps))
      stop("nndist.lpp does not agree with pairdist.lpp")

    nw <- nnwhich(Xspid)
    nwP <- g(pairdist(Xspid), 1)
    if(any(nw != nwP))
      stop("nnwhich.lpp does not agree with pairdist")
  }
  
  if(FULLTEST) {
    #' code blocks in nndist.lpp/nnwhich.lpp
    #' non-sparse network, interpreted code  
    Ad <- nndist(Xspid, method="interpreted") 
    Aw <- nnwhich(Xspid, method="interpreted")
    #' sparse network, older C code
    opa <- spatstat.options(Cnndistlpp=FALSE)
    Bd <- nndist(dendrite) 
    Bw <- nnwhich(dendrite) 
    spatstat.options(opa)
    #' undefined nearest neighbours
    Ed <- nndist(Xspid[1:3], k=1:3)
    Ew <- nnwhich(Xspid[1:3], k=1:3)
    
    #' trivial cases in nncross.lpp
    a <- nncross(runiflpp(0, simplenet), runiflpp(1, simplenet),
                 what="which", format="list")$which
    a <- nncross(runiflpp(0, simplenet), runiflpp(1, simplenet),
                 what="dist", format="list")$dist
  }

  if(ALWAYS) {
    #' compare algorithms             
    ZZ <- split(Xchic)
    XX <- ZZ$damage
    YY <- ZZ$assault
    op <- spatstat.options(Cnncrosslpp=FALSE)
    a <- nncross(XX, YY)
    spatstat.options(Cnncrosslpp=TRUE)
    b <- nncross(XX, YY)
    if(any(a$which != b$which))
      stop("Inconsistent values of nncross.lpp()$which from different C code")
    if(max(abs(a$dist - b$dist)) > eps)
      stop("Inconsistent values of nncross.lpp()$dist from different C code")

    spatstat.options(Cnncrosslpp=TRUE)
    b2 <- nncross(XX, YY, k=1:2, what="which")
    if(any(b2$which.1 != b$which))
      stop("inconsistent values of nncross.lpp()$which from k=1:2 and k=1")
    a2 <- nncross(XX, YY, k=1:2, what="dist")
    if(max(abs(a2$dist.1 - a$dist)) > eps)
      stop("Inconsistent values of nncross.lpp()$dist from k=1:2 and k=1")

    spatstat.options(Cnncrosslpp=TRUE)
    ii <- seq_len(npoints(XX))
    w1 <- nnwhich(XX)
    w2 <- nncross(XX, XX, iX=ii, iY=ii, what="which")
    w3 <- nncross(XX, XX, iX=ii, iY=ii, what="which", method="interpreted")
    if(any(w1 != w2))
      stop("nnwhich.lpp disagrees with nncross.lpp(iX, iY)")
    if(any(w2 != w3))
      stop("Different results for nncross.lpp(iX, iY, 'which') using R and C")
    d1 <- nndist(XX)
    d2 <- nncross(XX, XX, iX=ii, iY=ii, what="dist")
    d3 <- nncross(XX, XX, iX=ii, iY=ii, what="dist", method="interpreted")
    if(max(abs(d1-d2)) > eps)
      stop("nndist.lpp disagrees with nncross.lpp(iX, iY)")
    if(max(abs(d2-d3)) > eps)
      stop("Different results for nncross.lpp(iX, iY, 'dist') using R and C")
    spatstat.options(Cnncrosslpp=FALSE)
    w4 <- nncross(XX, XX, iX=ii, iY=ii, what="which")
    d4 <- nncross(XX, XX, iX=ii, iY=ii, what="dist")
    if(any(w2 != w4))
      stop("Different results for nncross.lpp(iX, iY, 'which') fast and slow C")
    if(max(abs(d2-d4)) > eps)
      stop("Different results for nncross.lpp(iX, iY, 'dist') fast and slow C")
    spatstat.options(Cnncrosslpp=TRUE)
  }
  
  reset.spatstat.options()

  if(FULLTEST) {
    ## test handling marginal cases
    xyd <- nncross(XX, YY[1])
    A <- runiflpp(5, simplenet)
    B <- runiflpp(2, simplenet)
    aaa <- nncross(A,B,k=3:5) #' all undefined
    aaa <- nncross(A,B,k=1:4) #' some undefined
    spatstat.options(Cnncrosslpp=FALSE)
    aaa <- nncross(A,B,k=3:5)
    aaa <- nncross(A,B,k=1:4)
    bbb <- nncross(B,A, iX=1:2, iY=1:5) # another code block
    spatstat.options(Cnncrosslpp=TRUE)
    reset.spatstat.options()
  }

  if(FULLTEST) {
    ## as.linnet.psp (Suman's example)
    Lines <- as.data.frame(as.psp(simplenet))
    newseg <- c(Lines[1,1:2], Lines[10,3:4])
    Lines <- rbind(Lines, newseg)
    Y <- as.psp(Lines, window=Window(simplenet))
    marks(Y) <- c(3, 4, 5, 5, 3, 4, 5, 5,5, 5,1)
    Z <- as.linnet(Y) # can crash if marks don't match segments
  
    ## Test linnet surgery code
    RL <- joinVertices(simplenet, matrix(c(2,3), ncol=2)) # redundant edge
    RZ <- joinVertices(Z, matrix(c(2,3), ncol=2), marks=6) # redundant edge
    JZ <- joinVertices(Z, matrix(c(2,7), ncol=2), marks=6) # new edge
    set.seed(42)
    X <- runiflpp(30, simplenet)
    V <- runiflpp(30, simplenet)
    XV <- insertVertices(X, V)
    validate.lpp.coords(XV, context="calculated by insertVertices")
    X0 <- insertVertices(X, x=numeric(0), y=numeric(0))
    ## vertices on boundary of new window
    LL <- simplenet[boundingbox(vertices(simplenet))]

    ## thinNetwork for lpp and linim
    Xthin <- thinNetwork(X, retainedges=1:3)
    D <- density(X, 0.1)
    Dthin <- thinNetwork(D, retainedges=1:3)
    
    ## Test [.lpp internal data
    B <- owin(c(0.1,0.7),c(0.19,0.6))
    XB <- X[B]
    validate.lpp.coords(XB, context="returned by [.lpp")
  }
  
  ## Tests related to linearK, etc
  testcountends <- function(X, r=100, s=1) {
    if(s != 1) {
      X <- rescale(X, s)
      r <- r/s
    }
    L <- as.linnet(X)
    n1 <- countends(L, X[1], r)
    n2 <- npoints(lineardisc(L, X[1], r, plotit=FALSE)$endpoints)
    if(n1 != n2)
      stop(paste("Incorrect result from countends:",
                 n1, "!=", n2, 
                 spatstat.utils::paren(paste("scale=", 1/s))),
           call.=FALSE)
  }

  if(ALWAYS) {
    ## original scale
    XU <- unmark(Xchic)
    testcountends(XU)
    ## finer scale
    testcountends(XU, s=1000)
    #' disconnected
    L <- thinNetwork(simplenet, retainedges = -c(3,8))
    S <- as.psp(L)
    x <- midpoints.psp(S)[1]
    len <- lengths_psp(S)[1]
    A <- lineardisc(L, x, len,  plotit=FALSE) #involves many segments of network
    B <- lineardisc(L, x, len/5, plotit=FALSE) # involves one segment of network
    op <- spatstat.options(Ccountends=FALSE)
    A <- lineardisc(L, x, len,  plotit=FALSE)
    B <- lineardisc(L, x, len/5, plotit=FALSE)
    reset.spatstat.options()
  
    ## Test algorithms for boundingradius.linnet
    L <- as.linnet(chicago, sparse=TRUE)
    L$boundingradius <- NULL # artificially remove
    opa <- spatstat.options(Clinearradius=FALSE)
    bR <- as.linnet(L, sparse=FALSE)$boundingradius
    spatstat.options(Clinearradius=TRUE)
    bC <- as.linnet(L, sparse=FALSE)$boundingradius
    spatstat.options(opa)
    if(abs(bR-bC) > 0.001 * (bR+bC)/2)
      stop("Disagreement between R and C algorithms for boundingradius.linnet",
           call.=FALSE)
  }

  if(FULLTEST) {
    ## linnet things
    is.connected(as.linnet(dendrite))
    zik <- rescale(Xchic, 39.37/12, "m")
    Simon <- simplenet
    unitname(Simon) <- list("metre", "metres", 0.5)
    b <- rescale(Simon)
    ds <- density(simplenet, 0.05)
  }

  if(ALWAYS) {
    ## invoke dist2dpath
    LS <- as.linnet(simplenet, sparse=TRUE)
    LF <- as.linnet(LS, sparse=FALSE)
    ## direct call dist2dpath
    d <- simplenet$dpath
    d[!simplenet$m] <- Inf
    diag(d) <- 0
    dd <- dist2dpath(d, method="interpreted")
    ra <- range(dd - simplenet$dpath)
    if(max(abs(ra)) > sqrt(.Machine$double.eps))
      stop("dist2dpath gives different answers in C and R code")
  }

  if(FULLTEST) {
    ## integral.linim with missing entries
    xcoord <- linfun(function(x,y,seg,tp) { x }, domain(Xchic))
    xcoord <- as.linim(xcoord, dimyx=32)
    integral(xcoord)

    ## Math.linim
    range(xcoord)
    stopifnot(is.linim(sqrt(xcoord)))
    stopifnot(is.linim(-xcoord))
    stopifnot(is.linim(xcoord + xcoord))
    stopifnot(is.linim(xcoord/3))

    ## options to plot.linim
    plot(xcoord, legend=FALSE)
    plot(xcoord, leg.side="top")
    plot(xcoord, style="width", leg.side="bottom")
    
    ## as.linim.linim
    xxcc <- as.linim(xcoord)
    xxcceps <- as.linim(xcoord, eps=15)
    xxccdel <- as.linim(xcoord, delta=30)
    df1 <- attr(xxcc, "df")
    df2 <- attr(xxccdel, "df")
    df3 <- resampleNetworkDataFrame(df1, df2)

    ## linim with complex values
    Zc <- as.im(function(x,y){(x-y) + x * 1i}, Frame(simplenet))
    Fc <- linim(simplenet, Zc)
    print(Fc)
    print(summary(Fc))
  
    ## linim with df provided
    Z <- as.im(function(x,y) {x-y}, Frame(simplenet))
    X <- linim(simplenet, Z)
    df <- attr(X, "df")
    XX <- linim(simplenet, Z, df=df)
    dfwithout <- df[, colnames(df) != "values"]
    XXX <- linim(simplenet, Z, df=dfwithout)
    plot(XXX, zlim=c(-1,1))
    plot(XXX, legend=FALSE)
    plot(XXX, leg.side="bottom")
  
    ## lpp with multiple columns of marks
    M <- Xchic
    marks(M) <- cbind(type=marks(M), data.frame(distnearest=nndist(M)))
    plot(M, main="")
    summary(M)
    MM <- cut(M)

    #' other cases
    CC <- cut(Xchic)
    nd <- nndist(Xspid)
    SX <- cut(Xspid %mark% nd, breaks=3)
    SX <- cut(Xspid, nd, breaks=c(0,100,200,Inf), include.lowest=TRUE)
  
    ## linequad
    Y <- Xsimple %mark% factor(rep(c("A", "B"), 3))
    aX <- linequad(Xsimple)
    aY <- linequad(Y)
    aXR <- linequad(Xsimple, random=TRUE)
    aYR <- linequad(Y, random=TRUE)
    P <- as.ppp(Xsimple)
    S <- as.psp(domain(Xsimple))
    d <- linequad(P, S)
    oop <- spatstat.options(Clinequad=FALSE)
    bX <- linequad(Xsimple)
    spatstat.options(oop)

    ## other internal utilities
    df <- pointsAlongNetwork(simplenet, 0.05)
    X <- as.ppp(df[,c("x", "y")], W=Frame(simplenet))
    A <- local2lpp(simplenet, seg=df$seg, tp=df$tp, X=X, df.only=FALSE)
    
    ## mark-mark scatterplot uses pairdist
    X <- runiflpp(20, simplenet) %mark% runif(20)
    markmarkscatter(X, 0.2)
    markmarkscatter(X[FALSE], 0.1)

    ## tree branches
    ## make a simple tree
    m <- simplenet$m
    m[8,10] <- m[10,8] <- FALSE
    L <- linnet(vertices(simplenet), m)
    tb <- treebranchlabels(L, 1)
    X <- runiflpp(30, L)
    ## delete branch B
    XminusB <- deletebranch(X, "b", tb)
    ## extract branch B
    XB <- extractbranch(X, "b", tb)

    ## cases of lintess()
    A <- lintess(simplenet) # argument df missing 
    S <- as.psp(simplenet)
    ns <- nsegments(S)
    df <- data.frame(seg=1:ns, t0=0, t1=1, tile=letters[1:ns])
    M <- data.frame(len=lengths_psp(S), ang=angles.psp(S))
    V <- lintess(simplenet, df, marks=M)
    
    ## methods for class lintess
    U <- unmark(V)
    U <- unstack(V)
    print(summary(V))
    W <- Window(V)
    plot(V, style="image")
    plot(V, style="width")

    ## linear tessellations infrastructure
    nX <- 100
    nY <- 20
    X <- runiflpp(nX, simplenet)
    Y <- runiflpp(nY, simplenet)
    tes <- divide.linnet(Y)
    cX <- coords(X)
    iI <- lineartileindex(cX$seg, cX$tp, tes, method="interpreted")
    iC <- lineartileindex(cX$seg, cX$tp, tes, method="C")
    iE <- lineartileindex(cX$seg, cX$tp, tes, method="encode")
    if(!identical(iI,iC))
      stop("conflicting results from lineartileindex (interpreted vs C)")
    if(!identical(iI,iE))
      stop("conflicting results from lineartileindex (interpreted vs encoded)")
    iA <- as.linfun(tes)(X)
    if(!identical(iI, iA))
      stop("disagreement between as.linfun.lintess and lineartileindex")

    ## intersection of lintess
    X <- divide.linnet(runiflpp(4, simplenet))
    Y <- divide.linnet(runiflpp(3, simplenet))
    nX <- summary(X)$nt
    nY <- summary(Y)$nt
    marks(X) <- factor(letters[1L + (seq_len(nX) %% 2)])
    marks(Y) <- runif(nY)
    Zmm <- intersect.lintess(X,Y)
    Zum <- intersect.lintess(unmark(X),Y)
    Zmu <- intersect.lintess(X,unmark(Y))

  }

  if(FULLTEST) {
    #' handling by 'solist', 'unstack', 'plot.solist' etc
    L <- simplenet
    X <- runiflpp(5, L) %mark% cbind(a=1:5, b=letters[1:5])
    ns <- nsegments(L)
    df <- data.frame(seg=1:ns, t0=0, t1=1, tile=letters[1:ns])
    S <- lintess(L, df)
    f <- as.linfun(S)
    g <- as.linfun(S, values=seq_len(nsegments(L)))
    V <- as.linim(f)
    Z <- as.linim(g)
    shebang <- solist(L=L, X=X, S=S, f=f, g=g, V=V, Z=Z)
    plot(shebang)
    plot(shebang, valuesAreColours=FALSE)
    kapow <- unstack(shebang)
    plot(kapow)
  }

  #' kernel density estimation
  X <- Xsimple[1:5]
  w <- runif(npoints(X))
  if(ALWAYS) {
    #' density.lpp -> densityHeat, includes platform-dependent code
    D <- density(X, 0.05)
    D <- density(X, 0.05, weights=w)
  }
  if(FULLTEST) {
    #' code blocks
    D <- density(X[FALSE], 0.05)
    D <- density(X, Inf)
    D <- density(X, 0.05, finespacing=TRUE) # }
    D <- density(X, 0.05, eps=0.008)        # }  code blocks in resolve.heat.steps
    D <- density(X, 0.05, dimyx=256)        # }
  }
  if(ALWAYS) {
    DX <- density(X, 0.05, at="points", fastmethod="a", debug=TRUE)
    DX <- density(X, 0.05, at="points", fast=FALSE,     debug=TRUE)
    ## densityfun.lpp, code blocks
    ff <- densityfun(X, 0.05, nsigma=Inf)
  }
  if(FULLTEST) {
    #' disconnected network
    L <- thinNetwork(simplenet, retainedges=-c(3,5))
    Y <- runiflpp(5, L)
    D <- density(Y, 0.05)
    D <- density(Y, 0.05, weights=w)
    D <- density(Y, Inf)
    g <- flatdensityfunlpp(Y, disconnect=FALSE)
    a <- flatdensityatpointslpp(Y, disconnect=FALSE)
    #' density.lpp -> densityEqualSplit
    D <- density(X, 0.05, kernel="e", weights=w)
    D <- density(X, Inf, kernel="e")
    D <- density(Y, 0.05, kernel="e", weights=w)
    D <- density(Y, Inf, kernel="e")
  }
  if(ALWAYS) {
    #' density.lpp -> densityQuick.lpp
    D <- density(X, 0.05, distance="e", weights=runif(5))
  }
  if(FULLTEST) {
    D <- density(X, Inf, distance="e")
    D <- density(Y, 0.05, distance="e", weights=runif(5)) 
    D <- density(Y, Inf, distance="e")
    ## example from Andrea Gilardi
    ## with duplicated points, and points at a vertex
    A <- runiflpp(5, simplenet)
    V <- lpp(vertices(simplenet)[2:4], simplenet)
    B <- superimpose(A, A[3], V)
    D <- density(B, sigma=0.2, distance="e", at="points")
    if(length(as.numeric(D)) != npoints(B))
      stop("density.lpp(at='points') returns wrong number of values")
    G <- superimpose(U=runiflpp(4, simplenet), B=B)
    b <- bw.relrisklpp(G, distance="e", nh=2)
  }
  if(FULLTEST) {
    #' densityVoronoi.lpp and related code
    densityVoronoi(X, f=0)
    densityVoronoi(X, f=1e-8)
    densityVoronoi(X, f=1)
    densityVoronoi(X[FALSE], f=0.5)
    XX <- X[rep(1:npoints(X), 4)]
    densityVoronoi(XX, f=0.99999, nrep=5)
    densityVoronoi(Y, f=0)
    densityVoronoi(Y, f=1e-8)
    densityVoronoi(Y, f=1)
    densityVoronoi(Y[FALSE], f=0.5)
    #' bandwidth selection
    bw.voronoi(X, nrep=4, prob=c(0.2, 0.4, 0.6))
    bw.lppl(X)
    sug <- seq(0.1, 0.3, by=0.05)
    bw.lppl(X, sigma=sug)
    bw.lppl(X, sigma=sug, shortcut=FALSE)
    bw.lppl(X, sigma=sug, distance="path", shortcut=FALSE)
  }
  if(ALWAYS) {
    #' inhomogeneous K and g
    SD <- split(Xdend)
    DT <- density(SD[["thin"]], 100, distance="euclidean")
    DS <- density(SD[["stubby"]], 100, distance="euclidean")
    Kii <- linearKcross.inhom(dendrite, "thin", "thin", DT, DT)
    Kij <- linearKcross.inhom(dendrite, "thin", "stubby", DT, DS,
                            correction="none", ratio=TRUE)
    gii <- linearpcfcross.inhom(dendrite, "thin", "thin", DT, DT)
    gij <- linearpcfcross.inhom(dendrite, "thin", "stubby", DT, DS,
                                correction="none", ratio=TRUE)
  }
  if(FULLTEST) {
    Kx <- linearKcross.inhom(dendrite[1], "thin", "stubby", DT, DS)
    gx <- linearpcfcross.inhom(dendrite[1], "thin", "stubby", DT, DS)
  }

  if(FULLTEST) {
    ## infrastructure for density.lpp
    L <- domain(Xchic)
    A <- resolve.heat.steps(100, L=L, dx=1)
    B <- resolve.heat.steps(100, L=L, dt=0.2)
    C <- resolve.heat.steps(100, L=L, niter=1e5)
    C <- resolve.heat.steps(100, L=L, niter=1e5, nsave=3)
    C <- resolve.heat.steps(100, L=L, niter=1e5, nsave=Inf)
    D <- resolve.heat.steps(100, L=L, dx=1, dt=0.2)
    E <- resolve.heat.steps(500, L=L, dt=0.5, iterMax=2e5)
    A <- resolve.heat.steps(1, L=simplenet, dt=2, dx=0.05)
    B <- resolve.heat.steps(1, L=simplenet)
    C <- resolve.heat.steps(1, L=simplenet, finespacing=FALSE)
    D <- resolve.heat.steps(1, seglengths=rep(0.7, 5), maxdegree=4, AMbound=7)
    ## vertices on boundary 
    L <- simplenet
    L <- L[boundingbox(vertices(L))]
    X <- as.lpp(0.41259, 0.6024, L=L)
    D <- density(X, 0.1)
  }

  if(FULLTEST) {
    #' multitype
    #' density.splitppx
    Z <- split(Xchic)[1:3]
    D <- density(Z, 7)
    #' relrisk.lpp for 3 types
    U <- do.call(superimpose, Z)
    A <- relrisk(U, 20, control=1, relative=TRUE)
    A <- relrisk(U, 20, control=1, relative=TRUE, at="points")
    #' relrisk.lpp for 2 types
    V <- do.call(superimpose, Z[1:2])
    A <- relrisk(V, 20, control=2, casecontrol=FALSE) # issues warning
    B <- relrisk(V, 20, control="assault", case=2, relative=TRUE)
    D <- relrisk(V, 20, control=1, case="burglary", relative=TRUE, at="points")
    #' bw.relrisklpp
    b1 <- bw.relrisklpp(V, hmax=3, fudge=0.01,
                        method="leastsquares", reference="sigma")
    b2 <- bw.relrisklpp(V, hmax=3, fudge=0.01,
                        method="KelsallDiggle", reference="uniform")
  }

  if(FULLTEST) {
    #' pairs.linim
    Z <- density(Xsimple, 0.5, distance="euclidean")
    pairs(solist(Z))
    pairs(solist(A=Z))
    U <- density(as.ppp(Xsimple), 0.5)
    pairs(solist(U, Z))
    pairs(solist(Z, U))
  }

  if(FULLTEST) {
    #' complex-valued functions and images
    f <- function(x,y,seg,tp) { x + y * 1i }
    g <- linfun(f, simplenet)
    h <- as.linim(g)
    plot(Re(h))
    plot(h)
    plot(g)
    integral(h)
    integral(g)
  }

  ## 'lixellate' - involves C code
  if(ALWAYS) {
    ## Cases where no subdivision occurs
    P <- runiflpp(4, simplenet)
    A <- lixellate(P, nsplit=1)
    B <- lixellate(P, eps=2)
    ## bug in 'lixellate' (Jakob Gulddahl Rasmussen)
    X <- ppp(c(0,1), c(0,0), owin())
    L <- linnet(X, edges = matrix(1:2, ncol=2))
    Y <- lpp(X, L)
    ## The left end point is OK
    lixellate(Y[1], nsplit=30)
    d <- density(Y[1], .1)
    ## The right end point gave an error
    lixellate(Y[2], nsplit=30)
    d <- density(Y[2], .1)
  }

  if(FULLTEST) {
    ## make some bad data and repair it
    L <- simplenet
    ## reverse edges
    a <- L$from[c(FALSE,TRUE)]
    L$from[c(FALSE,TRUE)] <- L$to[c(FALSE,TRUE)]  
    L$to[c(FALSE,TRUE)] <- a
    ## duplicate edges
    ns <- nsegments(L)
    ii <- c(seq_len(ns), 2)
    L$from <- L$from[ii]
    L$to   <- L$to[ii]
    L$lines <- L$lines[ii]
    ##
    Y <- repairNetwork(L)
    ## add points
    X <- runiflpp(4, L)
    Z <- repairNetwork(X)
  }

  if(FULLTEST) {
    #' random generation bugs and code blocks
    A <- runiflpp(5, simplenet, nsim=2)
    D <- density(A[[1]], 0.3)
    B <- rpoislpp(D, nsim=2)
    stopifnot(is.multitype(rlpp(c(10,5), list(a=D,b=D))))
    stopifnot(is.multitype(rlpp(5,       list(a=D,b=D))))
    stopifnot(is.multitype(rlpp(c(10,5), D)))
  }

  ## rhohat.lppm
  if(FULLTEST) {
    fut <- lppm(Xspid ~ 1)
    rx <- rhohat(fut, "x")
    Z <- linfun(function(x,y,seg,tp) { x }, domain(Xspid))
    rZ <- rhohat(fut, Z)
    U <- predict(rx)
    U <- predict(rZ)
    Y <- simulate(rx)
    Y <- simulate(rZ)
    futm <- lppm(Xchic ~ x + marks)
    ry <- rhohat(futm, "y")
    U <- predict(ry)
    Y <- simulate(ry)
  }

  if(ALWAYS) {
    #' new code for pairdist.lpp
    X  <- runiflpp(10, simplenet)
    dC <- pairdist(X, method="C")
    dI <- pairdist(X, method="interpreted")
    if(max(abs(dC - dI)) > 0.01)
      stop("pairdist.lpp: disagreement between C and R")
    XS <- as.lpp(X, sparse=TRUE)
    dS <- pairdist(XS)
    if(max(abs(dC - dS)) > 0.01)
      stop("pairdist.lpp: disagreement between sparse and non-sparse C")
    dU <- pairdist(XS, method="testsymm") # secret option
    if(max(abs(dS - dU)) > 0.01)
      stop("pairdist.lpp: disagreement between symmetric and asymmetric")

    #' new code for crossdist.lpp
    #' non-sparse
    v <- split(Xchic) 
    X <- v$cartheft
    Y <- v$burglary
    dC <- crossdist(X, Y, method="C")
    dI <- crossdist(X, Y, method="interpreted")
    if(max(abs(dC - dI)) > 0.01)
      stop("crossdist.lpp (non-sparse): disagreement between C and R")
    #' convert to sparse
    Chuck <- as.lpp(Xchic, sparse=TRUE)
    V <- split(Chuck)
    X <- V$cartheft
    Y <- V$burglary
    dS <- crossdist(X, Y)
    if(max(abs(dS - dC)) > 0.01)
      stop("crossdist.lpp: disagreement between sparse and non-sparse")
    #' disconnected 
    L <- thinNetwork(simplenet, retainedges = -c(3,8))
    X <- runiflpp(20, L)
    Y <- runiflpp(15, L)
    d <- crossdist(X,Y)

    ## example where the path is very long (covers a previous bug)
    X <- dendrite[c(349,563)]
    a <- pairdist(X, method="testsymm")
    if(max(abs(a-t(a))) > 0.01)
      stop("pairdist.lpp: asymmetry for long distances")
    b <- pairdist(as.lpp(X, sparse=FALSE))
    if(max(abs(a-b)) > 0.01)
      stop("pairdist.lpp: disagreement sparse vs non-sparse for long distance")
  }
})

reset.spatstat.options()

#'
#'   lppmodels.R
#'
#'   Tests of lppm and class support
#' 
#'   $Revision: 1.3 $ $Date: 2025/01/18 03:43:52 $
#'


local({
  if(ALWAYS) {
    fit0 <- lppm(spiders)
    fit1 <- lppm(spiders ~ x)
    summary(fit0)
    summary(fit1)
    pseudoR2(fit0)
    pseudoR2(fit1)
  }
  if(FULLTEST) {
    fit2 <- lppm(chicago ~ x+y)
    summary(fit2)
    pseudoR2(fit2)    
  }
  if(ALWAYS) {
    X <- runiflpp(10, simplenet)
    Z <- distfun(runiflpp(10, simplenet))
    fit3 <- lppm(X ~ Z)
    summary(fit3)
    pseudoR2(fit3)
  }

  Window(fit1)

  if(ALWAYS) a <- model.images(fit0)
  if(FULLTEST) {
    a <- model.images(fit1)
    a <- model.images(fit2)
    a <- model.images(fit3)
  }
  if(ALWAYS)
    b <- model.matrix(fit0)
  if(FULLTEST) {
    b <- model.matrix(fit1)
    b <- model.matrix(fit2)
    b <- model.matrix(fit3)
  }

  if(ALWAYS) 
    is.multitype(fit0)
  if(FULLTEST) {
    is.multitype(fit1)
    is.multitype(fit2)
    is.multitype(fit3)
  }
  
  if(ALWAYS) fit0e <- emend(fit0)
  if(FULLTEST) {
    fit1e <- emend(fit1)
    fit2e <- emend(fit2)
    fit3e <- emend(fit3)
  }

  if(FULLTEST) {
    #' handling of lintess covariates
    df <- data.frame(seg=1:10, t0=0, t1=1, tile=rep(c("A", "B"), 5))
    V <- lintess(simplenet, df)
    X <- runiflpp(20, simplenet)
    mod <- lppm(X ~ V)
    Lam <- predict(mod)
  }

  #' fundamental utilities:
  #' spatialCovariateEvidence (was: evalCovar)
  ycoord <- function(x,y) { y }
  if(ALWAYS) YS <- as.linim(ycoord, L=domain(spiders))
  if(FULLTEST) YC <- as.linim(ycoord, L=domain(chicago))

  if(ALWAYS) aT <- spatialCovariateEvidence(fit1, YS, interpolate=TRUE)
  if(FULLTEST) {
    aF <- spatialCovariateEvidence(fit1, YS, interpolate=FALSE)
    dT <- spatialCovariateEvidence(fit1, ycoord, interpolate=TRUE)
    dF <- spatialCovariateEvidence(fit1, ycoord, interpolate=FALSE)
    bT <- spatialCovariateEvidence(fit2, YC, interpolate=TRUE)
    bF <- spatialCovariateEvidence(fit2, YC, interpolate=FALSE)
    cT <- spatialCovariateEvidence(fit2, ycoord, interpolate=TRUE)
    cF <- spatialCovariateEvidence(fit2, ycoord, interpolate=FALSE)
  }
  
})

