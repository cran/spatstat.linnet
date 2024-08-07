\name{linearK}
\alias{linearK}
\title{
  Linear K Function
}
\description{
  Computes an estimate of the linear \eqn{K} function
  for a point pattern on a linear network.
}
\usage{
linearK(X, r=NULL, ..., correction="Ang", ratio=FALSE)
}
\arguments{
  \item{X}{
    Point pattern on linear network (object of class \code{"lpp"}).
  }
  \item{r}{
    Optional. Numeric vector of values of the function argument \eqn{r}.
    There is a sensible default.
  }
  \item{\dots}{
    Ignored.
  }
  \item{correction}{
    Geometry correction.
    Either \code{"none"} or \code{"Ang"}. See Details.
  }
  \item{ratio}{
    Logical. 
    If \code{TRUE}, the numerator and denominator of
    the estimate will also be saved,
    for use in analysing replicated point patterns.
  }
}
\details{
  This command computes the
  linear \eqn{K} function from point pattern data on a linear network.

  If \code{correction="none"}, the calculations do not include
  any correction for the geometry of the linear network. The result is the
  network \eqn{K} function as defined by Okabe and Yamada (2001).

  If \code{correction="Ang"}, the pair counts are weighted using
  Ang's correction (Ang, 2010; Ang et al, 2012). 
}
\value{
  Function value table (object of class \code{"fv"}).
}
\author{
  \wei and \adrian.
}
\references{
  Ang, Q.W. (2010) Statistical methodology for spatial point patterns
  on a linear network. MSc thesis, University of Western Australia.

  Ang, Q.W., Baddeley, A. and Nair, G. (2012)
  Geometrically corrected second-order analysis of 
  events on a linear network, with applications to
  ecology and criminology.
  \emph{Scandinavian Journal of Statistics} \bold{39}, 591--617.

  Okabe, A. and Yamada, I. (2001) The K-function method on a network and
  its computational implementation. \emph{Geographical Analysis}
  \bold{33}, 271-290.
}

\seealso{
  \code{\link[spatstat.explore]{compileK}},
  \code{\link{lpp}}
}
\examples{
  X <- rpoislpp(5, simplenet)
  linearK(X)
  linearK(X, correction="none")
}
\keyword{spatial}
\keyword{nonparametric}
\concept{Linear network}
