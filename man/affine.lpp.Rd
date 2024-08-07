\name{affine.lpp} 
\alias{affine.lpp} 
\alias{shift.lpp} 
\alias{rotate.lpp}
\alias{rescale.lpp}
\alias{scalardilate.lpp}
\title{Apply Geometrical Transformations to Point Pattern on a Linear Network}
\description{
  Apply geometrical transformations to a point pattern on a linear network.
}
\usage{
  \method{affine}{lpp}(X, mat=diag(c(1,1)), vec=c(0,0), \dots)

  \method{shift}{lpp}(X, vec=c(0,0), \dots, origin=NULL)

  \method{rotate}{lpp}(X, angle=pi/2, \dots, centre=NULL)

  \method{scalardilate}{lpp}(X, f, \dots)

  \method{rescale}{lpp}(X, s, unitname)
}
\arguments{
  \item{X}{Point pattern on a linear network (object of class \code{"lpp"}).}
  \item{mat}{Matrix representing a linear transformation.}
  \item{vec}{Vector of length 2 representing a translation.}
  \item{angle}{Rotation angle in radians.}
  \item{f}{Scalar dilation factor.}
  \item{s}{
    Unit conversion factor: the new units are \code{s} times the old units.
  }
  \item{\dots}{
    Arguments passed to other methods.
  }
  \item{origin}{
    Character string determining a location
    that will be shifted to the origin. Options are
    \code{"centroid"}, \code{"midpoint"} and \code{"bottomleft"}.
    Partially matched. 
  }
  \item{centre}{
    Centre of rotation.
    Either a vector of length 2, or a character string
    (partially matched to \code{"centroid"}, \code{"midpoint"}
    or \code{"bottomleft"}).
    The default is the coordinate origin \code{c(0,0)}.
  }
  \item{unitname}{
    Optional. New name for the unit of length.
    A value acceptable to the function \code{\link[spatstat.geom]{unitname<-}}
  }
}
\value{
  Another point pattern on a linear network (object of class
  \code{"lpp"}) 
  representing the
  result of applying the geometrical transformation.
}
\details{
  These functions are methods for the generic functions
  \code{\link[spatstat.geom]{affine}},
  \code{\link[spatstat.geom]{shift}},
  \code{\link[spatstat.geom]{rotate}},
  \code{\link[spatstat.geom]{rescale}} and
  \code{\link[spatstat.geom]{scalardilate}}
  applicable to objects of class \code{"lpp"}.

  All of these functions
  perform geometrical transformations on the object \code{X},
  except for \code{rescale}, which simply rescales the units of length.
}
\seealso{
  \code{\link{lpp}}.
  
  Generic functions
  \code{\link[spatstat.geom]{affine}},
  \code{\link[spatstat.geom]{shift}},
  \code{\link[spatstat.geom]{rotate}},
  \code{\link[spatstat.geom]{scalardilate}},
  \code{\link[spatstat.geom]{rescale}}.
}
\examples{
  X <- rpoislpp(2, simplenet)
  U <- rotate(X, pi)
  V <- shift(X, c(0.1, 0.2))
  stretch <- diag(c(2,3))
  Y <- affine(X, mat=stretch)
  shear <- matrix(c(1,0,0.6,1),ncol=2, nrow=2)
  Z <- affine(X, mat=shear, vec=c(0, 1))
}
\author{
  \adrian
  and \rolf
}
\keyword{spatial}
\keyword{math}
\concept{Geometrical transformations}
\concept{Linear network}
