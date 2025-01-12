% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/canton_CH.R
\name{canton_namesStrict}
\alias{canton_namesStrict}
\title{Convert Swiss canton names to different languages and abbreviations}
\arguments{
\item{query}{a character vector of Swiss canton names in any language}

\item{output}{a character string, the ouput format}
}
\description{
Convert Swiss canton names to different languages and abbreviations
}
\details{
See \code{canton_CH}
}
\examples{
canton_query <- c('Argovie', 'Appenzell Rh.-I.', 'St. Gallen', 'Zürich', 'Vaud')
canton_namesStrict(canton_query)
canton_namesStrict(canton_query, output = "eng")
}
