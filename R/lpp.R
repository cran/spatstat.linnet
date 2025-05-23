#
# lpp.R
#
#  $Revision: 1.85 $   $Date: 2024/06/16 02:02:52 $
#
# Class "lpp" of point patterns on linear networks

lpp <- function(X, L, ...) {
  stopifnot(inherits(L, "linnet"))
  if(missing(X) || is.null(X)) {
    ## empty pattern
    df <- data.frame(x=numeric(0), y=numeric(0))
    lo <- data.frame(seg=integer(0), tp=numeric(0))
  } else {
    localnames <- c("seg", "tp")
    spatialnames <- c("x", "y")
    allcoordnames <- c(spatialnames, localnames)
    if(is.matrix(X)) X <- as.data.frame(X)
    if(checkfields(X, localnames)) {
      #' X includes at least local coordinates
      X <- as.data.frame(X)
      #' validate local coordinates
      if(nrow(X) > 0) {
        X$seg <- as.integer(X$seg)
        X$tp  <- as.double(X$tp)
        nedge <- nsegments(L)
        if(with(X, any(seg < 1 | seg > nedge)))
          stop("Segment index coordinate 'seg' exceeds bounds")
        if(with(X, any(tp < 0 | tp > 1)))
          stop("Local coordinate 'tp' outside [0,1]")
      }
      if(!checkfields(X, spatialnames)) {
        #' data give local coordinates only
        #' reconstruct x,y coordinates from local coordinates
        Y <- local2lpp(L, X$seg, X$tp, df.only=TRUE)
        X[,spatialnames] <- Y[,spatialnames,drop=FALSE]
      }
      #' local coordinates
      lo <- X[ , localnames, drop=FALSE]
      #' spatial coords and marks
      marknames <- setdiff(names(X), allcoordnames)
      df <- X[, c(spatialnames, marknames), drop=FALSE]
    } else {
      #' local coordinates must be computed from spatial coordinates
      if(!is.ppp(X))
        X <- as.ppp(X, W=L$window, ...)
      #' project to segment
      pro <- project2segment(X, as.psp(L))
      #' projected points (spatial coordinates and marks)
      df  <- as.data.frame(pro$Xproj)
      #' local coordinates
      lo  <- data.frame(seg = as.integer(pro$mapXY),
                        tp  = as.double(pro$tp))
    }
  }
  # combine spatial, local, marks
  nmark <- ncol(df) - 2
  if(nmark == 0) {
    df <- cbind(df, lo)
    ctype <- c(rep("s", 2), rep("l", 2))
  } else {
    df <- cbind(df[,1:2], lo, df[, -(1:2), drop=FALSE])
    ctype <- c(rep("s", 2), rep("l", 2), rep("m", nmark))
  }
  out <- ppx(data=df, domain=L, coord.type=ctype)
  class(out) <- c("lpp", class(out))
  return(out)
}

print.lpp <- function(x, ...) {
  stopifnot(inherits(x, "lpp"))
  splat("Point pattern on linear network")
  sd <- summary(x$data)
  np <- sd$ncases
  nama <- sd$col.names
  splat(np, ngettext(np, "point", "points"))
  ## check for unusual coordinates
  ctype <- x$ctype
  nam.m <- nama[ctype == "mark"]
  nam.t <- nama[ctype == "temporal"]
  nam.c <- setdiff(nama[ctype == "spatial"], c("x","y"))
  nam.l <- setdiff(nama[ctype == "local"], c("seg", "tp"))
  if(length(nam.c) > 0)
    splat("Additional spatial coordinates", commasep(sQuote(nam.c)))
  if(length(nam.l) > 0)
    splat("Additional local coordinates", commasep(sQuote(nam.l)))
  if(length(nam.t) > 0)
    splat("Additional temporal coordinates", commasep(sQuote(nam.t)))
  if((nmarks <- length(nam.m)) > 0) {
    if(nmarks > 1) {
      splat(nmarks, "columns of marks:", commasep(sQuote(nam.m)))
    } else {
      marx <- marks(x)
      if(is.factor(marx)) {
        exhibitStringList("Multitype, with possible types:", levels(marx))
      } else splat("Marks of type", sQuote(typeof(marx)))
    }
  }
  print(x$domain, ...)
  return(invisible(NULL))
}

plot.lpp <- function(x, ..., main, add=FALSE,
                     type=c("p", "n"),
                     use.marks=TRUE, which.marks=NULL,
                     legend=TRUE,
                     leg.side=c("left", "bottom", "top", "right"),
                     leg.args=list(),
                     show.all=!add, show.window=FALSE,
                     show.network=TRUE,
                     do.plot=TRUE, multiplot=TRUE) {
  if(missing(main))
    main <- short.deparse(substitute(x))
  type <- match.arg(type)
  if(missing(legend)) legend <- (type == "p")
  leg.side <- match.arg(leg.side)
  ## Handle multiple columns of marks as separate plots
  ##  (unless add=TRUE or which.marks selects a single column
  ##   or multiplot = FALSE)
  mx <- marks(x)
  if(type == "p" && use.marks && !is.null(dim(mx))) {
    implied.all <- is.null(which.marks)
    want.several <- implied.all || !is.null(dim(mx <- mx[,which.marks,drop=TRUE]))
    do.several <- want.several && !add && multiplot
    if(want.several)
      mx <- as.data.frame(mx) #' ditch hyperframe columns
    if(do.several) {
      ## generate one plot for each column of marks
      y <- solapply(mx, setmarks, x=x)
      out <- do.call(plot,
                     c(list(x=y, main=main, do.plot=do.plot,
                            show.window=show.window,
                            legend=legend, leg.side=leg.side, leg.args=leg.args),
                       list(...)))
      return(invisible(out))
    }
    if(is.null(which.marks)) {
      which.marks <- 1
      if(do.plot) message("Plotting the first column of marks")
    }
  }
  ## single plot 
  ## determine symbol map and plot area required, including legend
  P <- as.ppp(x)
  symap <- plot(P, ..., do.plot=FALSE,
                use.marks=use.marks, which.marks=which.marks,
                type=type, legend=legend, leg.side=leg.side, leg.args=leg.args)
  if(!do.plot) return(symap)
  
  ## initialise graphics space
  if(!add) {
    if(show.window) {
      plot(Window(P), main=main, invert=TRUE, ...)
    } else {
      b <- attr(symap, "bbox")
      plot(b, type="n", main=main, ..., show.all=show.all)
    }
  }
  ## plot linear network
  L <- as.linnet(x)
  if(show.network) 
    do.call.matched(plot.linnet,
                    resolve.defaults(list(x=quote(L), add=TRUE),
                                     list(...)),
                    extrargs=c("lty", "lwd", "col"))

  ## plot points
  if(type == "p") {
    ## extract relevant mark values
    if(use.marks) {
      marx <- marks(P)
      if(!is.null(dim(marx)))
        marx <- marx[, which.marks]
    } else marx <- NULL
    ## compute required data
    pnames <- symbolmapparnames(symap)
    if("shape" %in% pnames) {
      ## could be using crossticks
      ## compute direction of network at each data point
      ang <- angles.psp(as.psp(L))
      segX <- coords(x)$seg
      angX <- ang[segX] * 180/pi
    } else angX <- NULL
    ## plot points using previously-determined symbol map
    invoke.symbolmap(symap, marx, P, angleref=angX, add=TRUE)
  }
  
  if(legend && (symbolmaptype(symap) != "constant")) {
    ## plot legend
    legendmap <- if(length(leg.args) == 0) symap else 
                 do.call(update, append(list(object=quote(symap)), leg.args))
    dont.complain.about(legendmap)
    vertical <- (leg.side %in% c("left", "right"))
    legbox <- attr(symap, "legbox")
    if(is.null(legbox)) stop("Internal error - cannot find box for legend")
    do.call(plot.symbolmap,
            append(list(x=quote(legendmap),
                        main="", add=TRUE,
                        xlim=legbox$xrange, ylim=legbox$yrange,
                        side=leg.side,
                        vertical=vertical),
                   leg.args))
  }

  return(invisible(symap))
}


summary.lpp <- function(object, ...) {
  stopifnot(inherits(object, "lpp"))
  L <- object$domain
  result <- summary(L)
  np <- npoints(object)
  result$npoints <- np <- npoints(object)
  result$intensity <- np/result$totlength
  result$is.marked <- is.marked(object)
  result$is.multitype <- is.multitype(object)
  mks <- marks(object)  
  result$markformat <- mkf <- markformat(mks)
  switch(mkf,
         none = {
           result$multiple.marks <- FALSE
         },
         vector = {
           result$multiple.marks <- FALSE
           if(result$is.multitype) {
             tm <- as.vector(table(mks))
             tfp <- data.frame(frequency=tm,
                               proportion=tm/sum(tm),
                               intensity=tm/result$totlength,
                               row.names=levels(mks))
             result$marks <- tfp
             result$is.numeric <- FALSE
           } else {
             result$marks <- summary(mks)
             result$is.numeric <- is.numeric(mks)
           }
           result$marknames <- "marks"
           result$marktype <- typeof(mks)
         },
         dataframe = ,
         hyperframe = {
           result$multiple.marks <- TRUE
           result$marknames <- names(mks)
           result$is.numeric <- FALSE
           result$marktype <- mkf
           result$is.multitype <- FALSE
           result$marks <- summary(mks)
         })
  class(result) <- "summary.lpp"
  return(result)
}

print.summary.lpp <- function(x, ...) {
  what <- if(x$is.multitype) "Multitype point pattern" else
          if(x$is.marked) "Marked point pattern" else "Point pattern"
  splat(what, "on linear network")
  splat(x$npoints, "points")
  splat("Linear network with",
        x$nvert, "vertices and",
        x$nline, "lines")
  u <- x$unitinfo
  dig <- getOption('digits')
  splat("Total length", signif(x$totlength, dig), u$plural, u$explain)
  splat("Average intensity", signif(x$intensity, dig),
        "points per", if(u$vanilla) "unit length" else u$singular)
  if(x$is.marked) {
    if(x$multiple.marks) {
      splat("Mark variables:", commasep(x$marknames, ", "))
      cat("Summary of marks:\n")
      print(x$marks)
    } else if(x$is.multitype) {
      cat("Types of points:\n")
      print(signif(x$marks,dig))
    } else {
      splat("marks are ",
            if(x$is.numeric) "numeric, ",
            "of type ", sQuote(x$marktype),
            sep="")
      cat("Summary:\n")
      print(x$marks)
    }
  } else splat("Unmarked")
  print(x$win, prefix="Enclosing window: ")
  invisible(NULL)
}

intensity.lpp <- function(X, ...) {
  len <- sum(lengths_psp(as.psp(as.linnet(X))))
  if(is.multitype(X)) table(marks(X))/len else npoints(X)/len
}

## Moved to spatstat.geom
##
## is.lpp <- function(x) {
##   inherits(x, "lpp")
## }

is.multitype.lpp <- function(X, na.action="warn", ...) {
  marx <- marks(X)
  if(is.null(marx))
    return(FALSE)
  if((is.data.frame(marx) || is.hyperframe(marx)) && ncol(marx) > 1)
    return(FALSE)
  if(!is.factor(marx))
    return(FALSE)
  if((length(marx) > 0) && anyNA(marx))
    switch(na.action,
           warn = {
             warning(paste("some mark values are NA in the point pattern",
                           short.deparse(substitute(X))))
           },
           fatal = {
             return(FALSE)
           },
           ignore = {}
           )
  return(TRUE)
}

as.lpp <- function(x=NULL, y=NULL, seg=NULL, tp=NULL, ...,
                   marks=NULL, L=NULL, check=FALSE, sparse) {
  nomore <- is.null(y) && is.null(seg) && is.null(tp)
  if(inherits(x, "lpp") && nomore) {
    X <- x
    if(!missing(sparse) && !is.null(sparse))
      X$domain <- as.linnet(domain(X), sparse=sparse)
  } else {
    if(!inherits(L, "linnet"))
      stop("L should be a linear network")
    if(!missing(sparse) && !is.null(sparse))
      L <- as.linnet(L, sparse=sparse)
    if(is.ppp(x) && nomore) {
      X <- lpp(x, L)
    } else if(is.data.frame(x) && nomore) {
      X <- do.call(as.lpp,
                   resolve.defaults(as.list(x),
                                    list(...),
                                    list(marks=marks, L=L, check=check)))
    } else if(is.null(x) && is.null(y) && !is.null(seg) && !is.null(tp)){
      X <- lpp(data.frame(seg=seg, tp=tp), L=L)
    } else {
      if(is.numeric(x) && length(x) == 2 && is.null(y)) {
        xy <- list(x=x[1L], y=x[2L])
      } else  {
        xy <- xy.coords(x,y)[c("x", "y")]
      }
      if(!is.null(seg) && !is.null(tp)) {
        # add segment map information
        xy <- append(xy, list(seg=seg, tp=tp))
      } else {
        # convert to ppp, typically suppressing check mechanism
        xy <- as.ppp(xy, W=as.owin(L), check=check)
      }
      X <- lpp(xy, L)
    }
  }
  if(!is.null(marks))
    marks(X) <- marks
  return(X)
}

as.ppp.lpp <- function(X, ..., fatal=TRUE) {
  verifyclass(X, "lpp", fatal=fatal)
  L <- X$domain
  Y <- as.ppp(coords(X, temporal=FALSE, local=FALSE),
              W=L$window, check=FALSE)
  if(!is.null(marx <- marks(X))) {
    if(is.hyperframe(marx)) marx <- as.data.frame(marx)
    marks(Y) <- marx
  }
  return(Y)
}

Window.lpp <- function(X, ...) { as.owin(X) }

"Window<-.lpp" <- function(X, ..., check=TRUE, value) {
  if(check) {
    X <- X[value]
  } else {
    Window(X$domain, check=FALSE) <- value
  }
  return(X)
}

as.owin.lpp <- function(W,  ..., fatal=TRUE) {
  as.owin(as.ppp(W, ..., fatal=fatal))
}

domain.lpp <- function(X, ...) { as.linnet(X) }

as.linnet.lpp <- function(X, ..., fatal=TRUE, sparse) {
  verifyclass(X, "lpp", fatal=fatal)
  L <- X$domain
  if(!missing(sparse))
    L <- as.linnet(L, sparse=sparse)
  return(L)
}
  
unitname.lpp <- function(x) {
  u <- unitname(x$domain)
  return(u)
}

"unitname<-.lpp" <- function(x, value) {
  w <- x$domain
  unitname(w) <- value
  x$domain <- w
  return(x)
}

"marks<-.lpp" <- function(x, ..., value) {
  NextMethod("marks<-")
}
  
unmark.lpp <- function(X) {
  NextMethod("unmark")
}

as.psp.lpp <- function(x, ..., fatal=TRUE){
  verifyclass(x, "lpp", fatal=fatal)
  return(x$domain$lines)
}

nsegments.lpp <- function(x) {
  return(x$domain$lines$n)
}

local2lpp <- function(L, seg, tp, X=NULL, df.only=FALSE) {
  stopifnot(inherits(L, "linnet"))
  if(is.null(X)) {
    # map to (x,y)
    Ldf <- as.data.frame(L$lines)
    dx <- with(Ldf, x1-x0)
    dy <- with(Ldf, y1-y0)
    x <- with(Ldf, x0[seg] + tp * dx[seg])
    y <- with(Ldf, y0[seg] + tp * dy[seg])
  } else {
    x <- X$x
    y <- X$y
  }
  # compile into data frame
  data <- data.frame(x=x, y=y, seg=seg, tp=tp)
  if(df.only) return(data)
  ctype <- c("s", "s", "l", "l")
  out <- ppx(data=data, domain=L, coord.type=ctype)
  class(out) <- c("lpp", class(out))
  return(out)
}

####################################################
# subset extractor
####################################################

"[.lpp" <- function (x, i, j, drop=FALSE, ..., snip=TRUE) {
  if(!missing(i) && !is.null(i)) {
    if(is.owin(i)) {
      # spatial domain: call code for 'j'
      xi <- x[,i,snip=snip]
    } else {
      # usual row-type index
      da <- x$data
      daij <- da[i, , drop=FALSE]
      xi <- ppx(data=daij, domain=x$domain, coord.type=as.character(x$ctype))
      if(drop)
        xi <- xi[drop=TRUE] # call [.ppx to remove unused factor levels
      class(xi) <- c("lpp", class(xi))
    }
    x <- xi
  } 
  if(missing(j) || is.null(j))
    return(x)
  stopifnot(is.owin(j))
  x <- repairNetwork(x)
  w <- j
  L <- x$domain
  if(is.vanilla(unitname(w)))
    unitname(w) <- unitname(x)
  if(snip) {
    ## Segments will be trimmed to lie wholly inside 'w'
    ## Insert new vertices at crossing points with boundary of 'w'
    b <- crossing.psp(as.psp(L), edges(w))
    x <- insertVertices(x, unique(b)) # updated 'x'
    L <- domain(x)                    # updated 'L'
    boundarypoints <- attr(x, "id") # remember which points were added
    ## Find vertices of updated network that lie inside 'w'
    vertinside <- inside.owin(L$vertices, w=w)
    ## Treat boundary points as being inside
    vertinside[boundarypoints] <- TRUE
  } else {
    ## Find vertices of original network that lie inside 'w'
    vertinside <- inside.owin(L$vertices, w=w)
  }
  ## Retain an edge if BOTH endpoints lie inside
  edgeinside <- vertinside[L$from] & vertinside[L$to]
  ## extract relevant subset of network
  xnew <- thinNetwork(x, retainedges=edgeinside)
  ## adjust window without checking
  Window(xnew, check=FALSE) <- w
  return(xnew)
}

####################################################
# affine transformations
####################################################

scalardilate.lpp <- function(X, f, ...) {
  trap.extra.arguments(..., .Context="In scalardilate(X,f)")
  check.1.real(f, "In scalardilate(X,f)")
  stopifnot(is.finite(f) && f > 0)
  Y <- X
  Y$data$x <- f * as.numeric(X$data$x)
  Y$data$y <- f * as.numeric(X$data$y)
  Y$domain <- scalardilate(X$domain, f)
  return(Y)
}

affine.lpp <- function(X,  mat=diag(c(1,1)), vec=c(0,0), ...) {
  verifyclass(X, "lpp")
  Y <- X
  Y$data[, c("x","y")] <- affinexy(X$data[, c("x","y")], mat=mat, vec=vec)
  Y$domain <- affine(X$domain, mat=mat, vec=vec, ...)
  return(Y)
}

shift.lpp <- function(X, vec=c(0,0), ..., origin=NULL) {
  verifyclass(X, "lpp")
  Y <- X
  Y$domain <- if(missing(vec)) {
                shift(X$domain, ..., origin=origin)
              } else {
                shift(X$domain, vec=vec, ..., origin=origin)
              }
  vec <- getlastshift(Y$domain)
  Y$data[, c("x","y")] <- shiftxy(X$data[, c("x","y")], vec=vec)
  # tack on shift vector
  attr(Y, "lastshift") <- vec
  return(Y)
}

rotate.lpp <- function(X, angle=pi/2, ..., centre=NULL) {
  verifyclass(X, "lpp")
  if(!is.null(centre)) {
    X <- shift(X, origin=centre)
    negorigin <- getlastshift(X)
  } else negorigin <- NULL
  Y <- X
  Y$data[, c("x","y")] <- rotxy(X$data[, c("x","y")], angle=angle)
  Y$domain <- rotate(X$domain, angle=angle, ...)
  if(!is.null(negorigin))
    Y <- shift(Y, -negorigin)
  return(Y)
}

rescale.lpp <- function(X, s, unitname) {
  if(missing(unitname)) unitname <- NULL
  if(missing(s)) s <- 1/unitname(X)$multiplier
  Y <- scalardilate(X, f=1/s)
  unitname(Y) <- rescale(unitname(X), s, unitname)
  return(Y)
}

superimpose.lpp <- function(..., L=NULL) {
  objects <- list(...)
  if(!is.null(L) && !inherits(L, "linnet"))
    stop("L should be a linear network")
  if(length(objects) == 0) {
    if(is.null(L)) return(NULL)
    emptyX <- lpp(list(x=numeric(0), y=numeric(0)), L)
    return(emptyX)
  }
  islpp <- unlist(lapply(objects, is.lpp))
  if(is.null(L) && !any(islpp))
    stop("Cannot determine linear network: no lpp objects given")
  nets <- unique(lapply(objects[islpp], as.linnet))
  if(length(nets) > 1)
    stop("Point patterns are defined on different linear networks")
  if(!is.null(L)) {
    nets <- unique(append(nets, list(L)))
    if(length(nets) > 1)
      stop("Argument L is a different linear network")
  }
  L <- nets[[1L]]
  ## convert list(x,y) to linear network, etc
  if(any(!islpp))
    objects[!islpp] <- lapply(objects[!islpp], lpp, L=L)
  ## concatenate coordinates 
  locns <- do.call(rbind, lapply(objects, coords))
  ## concatenate marks (or use names of arguments)
  marx <- superimposeMarks(objects, sapply(objects, npoints))
  ## make combined pattern
  Y <- lpp(locns, L)
  marks(Y) <- marx
  return(Y)
}

identify.lpp <- function(x, ...) {
  verifyclass(x, "lpp")
  if(dev.cur() == 1 && interactive()) {
    eval(substitute(plot(X), list(X=substitute(x))))
  }
  P <- as.ppp(x)
  id <- identify(P$x, P$y, ...)
  if(!is.marked(x)) return(id)
  marks <- as.data.frame(P)[id, -(1:2)]
  out <- cbind(data.frame(id=id), marks)
  row.names(out) <- NULL
  return(out)
}

cut.lpp <- function(x, z=marks(x), ...) {
  if(missing(z) || is.null(z)) {
    z <- marks(x, dfok=TRUE)
    if(is.null(z))
      stop("no data for grouping: z is missing, and x has no marks")
  } else {
    #' special objects
    if(inherits(z, "linim")) {
      z <- z[x, drop=FALSE]
    } else if(inherits(z, "linfun")) {
      z <- z(x)
    } else if(inherits(z, "lintess")) {
      z <- (as.linfun(z))(x)
    }
  }
  if(is.character(z)) {
    if(length(z) == npoints(x)) {
      # interpret as a factor
      z <- factor(z)
    } else if((length(z) == 1) && (z %in% colnames(df <- as.data.frame(x)))) {
      # interpret as the name of a column of marks or a coordinate
      zname <- z
      z <- df[, zname]
      if(zname == "seg") z <- factor(z)
    } else stop("format of argument z not understood") 
  }
  switch(markformat(z),
         none = stop("No data for grouping"),
         vector = {
           stopifnot(length(z) == npoints(x))
           g <- if(is.factor(z)) z else
                if(is.numeric(z)) cut(z, ...) else factor(z)
           marks(x) <- g
           return(x)
         },
         dataframe = ,
         hyperframe = {
           stopifnot(nrow(z) == npoints(x))
           #' extract atomic data
           z <- as.data.frame(z)
           if(ncol(z) < 1) stop("No suitable data for grouping")
           #' take first column of atomic data
           z <- z[,1L,drop=TRUE]
           g <- if(is.numeric(z)) cut(z, ...) else factor(z)
           marks(x) <- g
           return(x)
         },
         list = stop("Don't know how to cut according to a list"))
  stop("Format of z not understood")
}

points.lpp <- function(x, ...) {
  points(coords(x, spatial=TRUE, local=FALSE), ...)
}

connected.lpp <- function(X, R=Inf, ..., dismantle=TRUE) {
  if(!dismantle) {
    if(is.infinite(R)) {
      Y <- X %mark% factor(1)
      attr(Y, "retainpoints") <- attr(X, "retainpoints")
      return(Y)
    }
    check.1.real(R)
    stopifnot(R >= 0)
    nv <- npoints(X)
    close <- (pairdist(X) <= R)
    diag(close) <- FALSE
    ij <- which(close, arr.ind=TRUE)
    lab0 <- cocoEngine(nv, ij[,1] - 1L, ij[,2] - 1L, "connected.lpp")
    lab <- lab0 + 1L
    # Renumber labels sequentially 
    lab <- as.integer(factor(lab))
    # Convert labels to factor
    lab <- factor(lab)
    # Apply to points
    Y <- X %mark% lab
    attr(Y, "retainpoints") <- attr(X, "retainpoints")
    return(Y)
  }
  # first break the *network* into connected components
  L <- domain(X)
  lab <- connected(L, what="labels")
  if(length(levels(lab)) == 1) {
    XX <- solist(X)
  } else {
    subsets <- split(seq_len(nvertices(L)), lab)
    XX <- solist()
    for(i in seq_along(subsets)) 
      XX[[i]] <- thinNetwork(X, retainvertices=subsets[[i]])
  }
  # now find R-connected components in each dismantled piece
  YY <- solapply(XX, connected.lpp, R=R, dismantle=FALSE)
  if(length(YY) == 1)
    YY <- YY[[1]]
  return(YY)
}

text.lpp <- function(x, ...) {
  co <- coords(x)
  graphics::text.default(x=co$x, y=co$y, ...)
}
