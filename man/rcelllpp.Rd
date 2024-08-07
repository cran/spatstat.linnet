\name{rcelllpp}
\alias{rcelllpp}
\title{
  Simulate Cell Process on Linear Network
}
\description{
  Generate a realisation of the cell process on a linear network.
}
\usage{
rcelllpp(L, lambda, rnumgen = NULL, \dots, saveid=FALSE)
}
\arguments{
  \item{L}{
    Either a linear network (object of class \code{"linnet"})
    or a tessellation on a linear network (object of class \code{"lintess"}).
  }
  \item{lambda}{
    Intensity of the process (expected number of points per unit length),
  }
  \item{rnumgen}{
    Optional. Random number generator for the number of points
    in each cell.
  }
  \item{\dots}{
    Additional arguments to \code{rnumgen}.
  }
  \item{saveid}{
    Logical value indicating whether to save information
    about cell membership.
  }
}
\details{
  This function generates simulated realisations of a
  cell point process on a network, as described in Baddeley et al (2017).
  This is the analogue on a linear network of the two-dimensional
  cell point process of Baddeley and Silverman (1988).
  
  The argument \code{L} should be a tessellation on a linear network.
  Alternatively if \code{L} is a linear network, it is converted to a
  tessellation by treating each network segment as a tile in the tessellation.

  The cell process generates a point process by generating independent
  point processes inside each tile of the tessellation. Within each tile,
  given the number of random points in the tile, 
  the points are independent and uniformly distributed within the tile.

  By default (when \code{rnumgen} is not given), the number of points in
  a tile of length \code{t} is a random variable with
  mean and variance equal to \code{lambda * t}, generated by calling
  \code{\link[spatstat.random]{rcellnumber}}.

  If \code{rnumgen} is given, it should be a function with
  arguments \code{rnumgen(n, mu, \dots)} where \code{n} is the number of
  random integers to be generated, \code{mu} is the mean value of the
  distribution, and \code{\dots} are additional arguments, if needed.
  It will be called in the form \code{rnumgen(1, lambda * t, \dots)}
  to determine the number of random points falling in each tile of
  length \code{t}.
}
\value{
  Point pattern on a linear network (object of class \code{"lpp"}).
  If \code{saveid=TRUE}, the result has an attribute \code{"cellid"}
  which is a factor specifying the cell that contains each point.
}
\author{
  \adrian.
}
\seealso{
  \code{\link{rSwitzerlpp}}
}
\references{
  Baddeley, A.J. and Silverman, B.W. (1984)
  A cautionary example on the use of second-order methods for analyzing
  point patterns. \emph{Biometrics} \bold{40}, 1089-1094.

  Baddeley, A., Nair, G., Rakshit, S. and McSwiggan, G. (2017)
  \sQuote{Stationary} point processes are uncommon on
  linear networks. \emph{STAT} \bold{6}, {68--78}.
}
\examples{
   X <- rcelllpp(domain(spiders), 0.01)
   plot(X)
   plot(linearK(X))
}
\keyword{spatial}
\keyword{datagen}

\concept{Linear network}
