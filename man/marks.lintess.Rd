\name{marks.lintess}
\alias{marks.lintess}
\alias{marks<-.lintess}
\alias{unmark.lintess}
\title{Marks of a Tessellation on a Network}
\description{
  Extract or change the marks attached to
  the tiles of a tessellation on a linear network.
}
\usage{
\method{marks}{lintess}(x, \dots)           

\method{marks}{lintess}(x, \dots) <- value

\method{unmark}{lintess}(X)
}
\arguments{
  \item{x,X}{
    Tessellation on a linear network (object of class \code{"lintess"}).
  }
  \item{\dots}{
    Ignored.
  }
  \item{value}{
    Vector or data frame of mark values,
    or \code{NULL}.
  }
}
\value{
  For \code{marks(x)}, the result is a vector, factor or data frame,
  containing the mark values attached to the tiles of \code{x}.
  If there are no marks, the result is \code{NULL}.

  For \code{unmark(x)}, the result is the tessellation without marks.
  
  For \code{marks(x) <- value}, the result is the updated tessellation
  \code{x} (with the side-effect that the dataset \code{x} is updated in
  the current environment).
}
\details{
  These functions extract or change the marks
  attached to each of the tiles in the tessellation \code{x}.
  They are methods for the generic functions
  \code{\link[spatstat.geom]{marks}},
  \code{\link[spatstat.geom]{marks<-}} and \code{\link[spatstat.geom]{unmark}}
  for the class \code{"lintess"} of tessellations on a network.
    
  The expression \code{marks(x)} extracts the marks of \code{x}.
  The assignment \code{marks(x) <- value} assigns new marks to the
  dataset \code{x}, and updates the dataset \code{x} in the current
  environment. 
  
  The marks can be a vector, a factor, or a data frame.
  
  For the assignment \code{marks(x) <- value}, the \code{value}
  should be a vector or factor of length equal to the number of
  tiles in \code{x}, or a data frame with as many rows
  as there are tiles in \code{x}. If \code{value} is a single value,
  or a data frame with one row, then it will be replicated
  so that the same marks will be attached to each tile.
  
  To remove marks, use \code{marks(x) <- NULL} or \code{unmark(x)}.
}
\seealso{
  \code{\link{lintess}},
  \code{\link[spatstat.geom]{marks}},
  \code{\link[spatstat.geom]{marks<-}}
}
\examples{
  B <- lineardirichlet(runiflpp(5, simplenet))
  marks(B) <- letters[1:5]
}
\author{
  \spatstatAuthors.
}
\keyword{spatial}
\keyword{manip}
\concept{Tessellation}
\concept{Linear network}
