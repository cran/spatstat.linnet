\name{densityQuick.lpp}
\alias{densityQuick.lpp}
\title{
  Kernel Estimation of Intensity on a Network using a 2D Kernel
}
\description{
  Estimates the intensity of a point process on a linear network
  using a two-dimensional smoothing kernel.
}
\usage{
densityQuick.lpp(x, sigma=NULL, \dots,
         kernel="gaussian",
         at = c("pixels", "points"),
         what = c("estimate", "se", "var"),
         leaveoneout = TRUE,
         diggle = FALSE,
         edge2D = FALSE,
         weights = NULL,
         positive = FALSE)
}
\arguments{
  \item{x}{
    Point pattern on a linear network (object of class \code{"lpp"}).
  }
  \item{sigma}{
    Smoothing bandwidth. A single numeric value,
    in the same units as the coordinates of \code{x}.
    Alternatively \code{sigma} may be a function which selects a
    bandwidth when applied to \code{x},
    for example, \code{\link[spatstat.explore]{bw.scott.iso}} or \code{\link{bw.lppl}}.
    There is a sensible default.
  }
  \item{\dots}{
    Additional arguments passed to \code{\link[spatstat.geom]{as.mask}}
    to determine the pixel resolution, or arguments passed to
    \code{sigma} if it is a function.
  }
  \item{kernel}{
    String (partially matched) specifying the smoothing kernel.
    Current options are \code{"gaussian"}, \code{"epanechnikov"},
    \code{"quartic"} or \code{"disc"}.
  }
  \item{at}{
    String (partially matched)
    specifying whether to compute the intensity values
    at a fine grid of locations on the network
    (\code{at="pixels"}, the default) or
    only at the points of \code{x} (\code{at="points"}).
  }
  \item{what}{
    String (partially matched)
    specifying whether to calculate the intensity estimate,
    or its estimated standard error, or its estimated variance.
  }
  \item{leaveoneout}{
    Logical value indicating whether to compute a leave-one-out
    estimator. Applicable only when \code{at="points"}.
  }
  \item{diggle}{
    Logical value specifying whether to use the \sQuote{Diggle}
    correction. 
  }
  \item{edge2D}{
    Logical value specifying whether to apply the usual
    two-dimensional edge correction procedure to the numerator and
    denominator of the estimate.
}
  \item{weights}{
    Optional weights to be attached to the points.
    A numeric vector, an \code{expression}, or a pixel image.
  }
  \item{positive}{
    Logical value indicating whether to force the resulting values to be
    positive. Default is \code{FALSE} for the sake of speed.
  }
}
\details{
  Kernel smoothing is applied to the points of \code{x}
  using a two-dimensional Gaussian kernel, as described in Rakshit et al (2019).
  The result is a pixel image on the linear network (class
  \code{"linim"}) which can be plotted.

  Other techniques for kernel smoothing on a network are implemented in
  \code{\link{density.lpp}}. The main advantages of using a
  two-dimensional kernel are very fast computation and
  insensitivity to changes in the network geometry. The main
  disadvantage is that it ignores the connectivity of the network.
  See Rakshit et al (2019) for further explanation.

  The argument \code{sigma} specifies the smoothing bandwidth.
  If \code{sigma} is missing or \code{NULL},
  the default is one-eighth of the length of the shortest side
  of the bounding box of \code{x}.
  If \code{sigma} is a function in the \R language, it is assumed
  to be a bandwidth selection rule, and it will be applied to \code{x}
  to compute the bandwidth value.
}
\section{Infinite bandwidth}{
  If \code{sigma=Inf}, the resulting density estimate is 
  constant over all locations,
  and is equal to the average density of points per unit length.
  (If the network is not connected, then this rule
  is applied separately to each connected component of the network).
}
\value{
  If \code{at="pixels"} (the default),
  a pixel image on the linear network (object of class \code{"linim"}).

  If \code{at="points"}, a numeric vector with one entry for each point
  of \code{x}.
}
\references{
  Rakshit, S., Davies, T., Moradi, M., 
  McSwiggan, G., Nair, G., Mateu, J. and Baddeley, A. (2019)
  Fast kernel smoothing of point patterns on a large
  network using 2D convolution.
  \emph{International Statistical Review} \bold{87} (3) 531--556.
  DOI: 10.1111/insr.12327.
}
\author{
  Adrian Baddeley, Suman Rakshit and Tilman Davies
}
\seealso{
  \code{\link{density.lpp}}, the main function for density estimation
  on a network.

  \code{\link[spatstat.explore]{bw.scott}}, \code{\link[spatstat.explore]{bw.scott.iso}},
  \code{\link{bw.lppl}}for bandwidth selection.
}
\examples{
   X <- unmark(chicago)
   plot(densityQuick.lpp(X, 500))
   plot(densityQuick.lpp(X, 500, diggle=TRUE))
   plot(densityQuick.lpp(X, bw.scott.iso))
   plot(densityQuick.lpp(X, 500, what="se"))
}
\keyword{spatial}
\keyword{nonparametric}

\concept{Linear network}
