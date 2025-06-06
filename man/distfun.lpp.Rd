\name{distfun.lpp}
\Rdversion{1.1}
\alias{distfun.lpp}
\title{
  Distance Map on Linear Network
}
\description{
  Compute the distance function of a point pattern on a linear network.
}
\usage{
  \method{distfun}{lpp}(X, ..., k=1)
}
\arguments{
  \item{X}{
    A point pattern on a linear network
    (object of class \code{"lpp"}).
  }
  \item{k}{
    An integer. The distance to the \code{k}th nearest point
    will be computed.
  }
  \item{\dots}{
    Extra arguments are ignored. 
  }
}
\details{
  On a linear network \eqn{L}, the \dQuote{geodesic distance function}
  of a set of points \eqn{A} in \eqn{L} is the
  mathematical function \eqn{f} such that, for any 
  location \eqn{s} on \eqn{L},
  the function value \code{f(s)}
  is the shortest-path distance from \eqn{s} to \eqn{A}.

  The command \code{distfun.lpp} is a method for the generic command
  \code{\link[spatstat.geom]{distfun}}
  for the class \code{"lpp"} of point patterns on a linear network.

  If \code{X} is a point pattern on a linear network,
  \code{f <- distfun(X)} returns a \emph{function}
  in the \R language that represents the
  distance function of \code{X}. Evaluating the function \code{f}
  in the form \code{v <- f(x,y)}, where \code{x} and \code{y}
  are any numeric vectors of equal length containing coordinates of
  spatial locations, yields the values of the distance function at these
  locations. More efficiently \code{f} can be called in the form
  \code{v <- f(x, y, seg, tp)} where \code{seg} and \code{tp} are the local
  coordinates on the network. It can also be called as
  \code{v <- f(x)} where \code{x} is a point pattern on the same linear
  network.

  The function \code{f} obtained from \code{f <- distfun(X)}
  also belongs to the class \code{"linfun"}. 
  It can be printed and plotted immediately as shown in the Examples.
  It can be 
  converted to a pixel image using \code{\link{as.linim}}. 
}
\value{
  A \code{function} with arguments \code{x,y} and optional
  arguments \code{seg,tp}.
  It also belongs to the class \code{"linfun"} which has methods
  for \code{plot}, \code{print} etc.
}
\section{Distance values}{
  The values returned by the distance function
  \code{f <- distfun(X)} are distances,
  expressed as multiples of the unit of length of the spatial
  coordinates in \code{X}.
  The unit of length is given by \code{\link[spatstat.geom]{unitname}(X)}.

  Note that, if the unit of length in \code{X} is
  a composite expression such as \sQuote{2 microns},
  then the values of \code{f} are expressed as multiples
  of 2 microns, rather than being expressed in microns.
}
\seealso{
  \code{\link{linfun}},
  \code{\link{methods.linfun}}.

  To identify \emph{which} point is the nearest neighbour, see
  \code{\link{nnfun.lpp}}.
}
\examples{
   X <- runiflpp(3, simplenet)
   f <- distfun(X)
   f
   plot(f)

   # using a distfun as a covariate in a point process model:
   Y <- runiflpp(4, simplenet)
   fit <- lppm(Y ~D, covariates=list(D=f))

   f(Y)
}
\author{
  \spatstatAuthors.
}
\keyword{spatial}
\keyword{math}
\concept{Linear network}
