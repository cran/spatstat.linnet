\name{linearmarkequal}
\alias{linearmarkequal}
\title{
  Mark Connection Function for Multitype Point Pattern on Linear Network
}
\description{
  For a multitype point pattern on a linear network,
  estimate the mark connection function
  from points of type \eqn{i} to points of type \eqn{j}.
}
\usage{
linearmarkequal(X, r=NULL, \dots)
}
\arguments{
  \item{X}{The observed point pattern, 
    from which an estimate of the mark connection function
    \eqn{p_{ij}(r)}{p[ij](r)} will be computed.
    An object of class \code{"lpp"} which 
    must be a multitype point pattern (a marked point pattern
    whose marks are a factor).
  }
  \item{r}{numeric vector. The values of the argument \eqn{r}
    at which the function
    \eqn{p_{ij}(r)}{p[ij](r)} should be evaluated.
    There is a sensible default.
    First-time users are strongly advised not to specify this argument.
    See below for important conditions on \eqn{r}.
  }
  \item{\dots}{
    Arguments passed to \code{\link{linearpcfcross}}
    and \code{\link{linearpcf}}.
  }
}
\value{
  An object of class \code{"fv"} (see \code{\link[spatstat.explore]{fv.object}}).
}
\details{
  This is the mark equality function
  for a point pattern on a linear network (object of class \code{"lpp"}).

  The argument \code{r} is the vector of values for the
  distance \eqn{r} at which \eqn{p_{ij}(r)}{p[ij](r)}
  should be evaluated. 
  The values of \eqn{r} must be increasing nonnegative numbers
  and the maximum \eqn{r} value must not exceed the radius of the
  largest disc contained in the window.
}
\references{
  Baddeley, A, Jammalamadaka, A. and Nair, G. (2014)
  Multitype point process analysis of spines on the
  dendrite network of a neuron.
  \emph{Applied Statistics} (Journal of the Royal Statistical
   Society, Series C), \bold{63}, 673--694. 
}
\seealso{
 \code{\link{linearpcfcross}},
 \code{\link{linearpcf}},
 \code{\link{linearmarkconnect}},
 \code{\link[spatstat.explore]{markconnect}}.
}
\examples{
   if(interactive()) {
     X <- chicago
   } else {
     m <- sample(factor(c("A","B")), 20, replace=TRUE)
     X <- runiflpp(20, simplenet) \%mark\% m
   }
   p <- linearmarkequal(X)
}
\author{\adrian}
\keyword{spatial}
\keyword{nonparametric}

\concept{Linear network}
