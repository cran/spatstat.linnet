\name{as.owin.lpp}
\alias{as.owin.lpp}
\alias{as.owin.lppm}
\title{Convert Data on a Network to class owin}
\description{
  Converts data on a linear network
  into an object of class \code{"owin"}.
}
\usage{
 \method{as.owin}{lpp}(W, \dots, fatal=TRUE)

 \method{as.owin}{lppm}(W, \dots, fatal=TRUE)
}
\arguments{
  \item{W}{
    Data specifying an observation window, in any of several formats
    described under \emph{Details} below.
  }
  \item{fatal}{
    Logical value determining what to do
    if the data cannot be converted to an observation window.
    See Details.
  }
  \item{\dots}{Ignored.}
}
\value{
  An object of class \code{"owin"}
  (see \code{\link[spatstat.geom]{owin.object}})
  specifying an observation window.
}
\details{
  The class \code{"owin"} is a way of specifying the observation window
  for a point pattern. See \code{\link[spatstat.geom]{owin.object}}
  for an overview.
 
  The function \code{\link[spatstat.geom]{as.owin}}
  converts data in any of several formats 
  into an object of class \code{"owin"} for use by the \pkg{spatstat}
  package. The function \code{\link[spatstat.geom]{as.owin}}
  is generic, with methods
  for different classes of objects, and a default method.

  A long list of methods for
  \code{\link[spatstat.geom]{as.owin}}
  is documented in the help file for \code{\link[spatstat.geom]{as.owin}}
  in the \pkg{spatstat.geom} package.

  This help file documents additional methods applicable when \code{W} is
  \itemize{
    \item
    an object of class \code{"lpp"}
    representing a point pattern on a linear network.
    In this case, \code{as.owin} extracts the linear network
    and returns a window containing this network. 
    \item
    an object of class \code{"lppm"}
    representing a fitted point process model on a linear network.
    In this case, \code{as.owin} extracts the linear network
    and returns a window containing this network. 
  }
  If the argument \code{W} 
  cannot be converted to a window, then an error will
  be generated (if \code{fatal=TRUE}) or a value of \code{NULL}
  will be returned (if \code{fatal=FALSE}).
}
\seealso{
  \code{\link[spatstat.geom]{as.owin}},
  \code{\link[spatstat.geom]{owin.object}},
  \code{\link[spatstat.geom]{owin}}.

  Additional methods for \code{as.owin} may be provided
  by other packages outside the \pkg{spatstat} family.
}
\examples{
  as.owin(simplenet)
}
\author{
  \spatstatAuthors.
}
\keyword{spatial}
\keyword{manip}
 
 
\concept{Linear network}
