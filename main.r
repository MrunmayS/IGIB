library(stringr)
library(dplyr)
library(stringi)
library(tm)
library(SnowballC)
library(wordcloud)
library(RColorBrewer)
library(NLP)
library(topicmodels)
library(tidytext)
library(reshape2)
library(ggplot2)
library(pals)
library(Rcpp)

extract <- function(filename) {
  dataset <- read.delim(filename,
    header = FALSE,
    sep = "\t",
    quote = "",
    dec = " ",
    stringsAsFactors = FALSE
  )

  dataset <- as.data.frame(dataset)
  row_index <- seq_len(nrow(dataset)) %% 2
  details <- dataset[row_index == 1, ]
  abstract <- dataset[row_index == 0, ]
  abstract <- as.data.frame(abstract)
  details <- as.data.frame(details)

  doi <- extract_doi(details)
  author <- extract_author(details)
  title <- extract_title(details)

  article <- data.frame(doi, title, author, abstract)
  colnames(article) <- c("DOI Link", "Title", "Author", "Abstract")

  return(article)
}

extract_doi <- function(details_col) {
  pattern_doi <- "(\\w+):\\s(\\d+)[^ab  c](\\d+)[^abc](\\d+)[^abc](\\d+)[^abc](\\d+)[^abc](\\d+)"
  doi <- str_match(details_col[, 1], pattern_doi)
  doi <- as.data.frame(doi[, 1])
  return(doi)
}

extract_author <- function(details_col) {
  pattern_author <- "([A-Z][a-z]+)\\s([A-Z]*(\\.*))\\w+\\s(\\w+\\s*\\w*)(\\..)"
  author_name <- str_match(details_col[, 1], pattern_author)
  author <- as.data.frame(author_name[, 1])
  return(author)
}

extract_title <- function(details_col) {
  pattern_title <- "(?<=\")(.*?)(?=\")"
  title <- str_match(details_col[, 1], pattern_title)
  title <- as.data.frame(title[, 1])
  return(title)
}

extract_mutation <- function(abstract){
  pattern_mutation <-  "([a-z]{2})\\d+"
  mutation <- str_match(mutation[,1], pattern_mutation)
  mutation <- as.data.frame(mutation[,1])
  
}


dfn <- extract("citations.txt")

load("data_common_words.RData")


calculatedtm <- function(dataframe) {
  corpus <- VCorpus(VectorSource(dataframe))
  tospace <- content_transformer(
    function(x, pattern) {
      gsub(pattern, " ", x)
    }
  )
  processedcorpus <- tm_map(corpus, tospace, "/")
  processedcorpus <- tm_map(processedcorpus, tospace, "@")
  processedcorpus <- tm_map(processedcorpus, tospace, "#")


  processedcorpus <- tm_map(processedcorpus, content_transformer(tolower))
  processedcorpus <- tm_map(processedcorpus, removeNumbers)
  processedcorpus <- tm_map(processedcorpus, removeWords, stopwords("english"))
  processedcorpus <- tm_map(processedcorpus, removeWords, data_common_words)
  processedcorpus <- tm_map(processedcorpus, stripWhitespace)


  dtm <- TermDocumentMatrix(processedcorpus)
  return(dtm)
}

dtm <- calculatedtm(dfn$Abstract)

calculatefreq <- function(dtm) {
  dtm_matrix <- as.matrix(dtm)
  v <- sort(rowSums(dtm_matrix), decreasing = TRUE)
  d <- data.frame(word = names(v), freq = v)

  return(d)
}
freqtable <- calculatefreq(dtm)

View(freqtable)
makewordcloud <- function(x) {
  wordcloud(
    words = x$word,
    freq = x$freq,
    min.freq = 1,
    max.words = 250,
    random.order = FALSE,
    rot.per = 0.35,
    colors = brewer.pal(8, "Dark2")
  )
}

makewordcloud(freqtable)

makebarplot <- function(x){
  barplot(x[1:10, ]$freq, names.arg = x[1:10, ]$word,
          col ="lightgreen", main ="Top 10 most frequent words",
          ylab = "Word frequencies", xlab="Words")
}
makebarplot(freqtable)





