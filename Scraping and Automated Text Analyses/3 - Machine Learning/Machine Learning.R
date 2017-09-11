########################################
    ### MACHINE LEARNING USING R ###
########################################
        ### DENVER MCNENEY ###
  ### SFU WORKSHOP MARCH 14th 2016 ###
########################################

### WORKING DIRECTORY ###
getwd()

### INSTALLING PACKAGES FOR SESSION ###
PackagesToInstall <- c("e1071", "SparseM", "RTextTools", "tm")
install.packages(PackagesToInstall, repos = "http://cran.r-project.org")

### CALLING PACKAGES FOR SESSION ###
for (i in PackagesToInstall){
  library(i,character.only = TRUE)
}

### LOADING MOVIE REVIEWS ###

articles <- read.table("moviereviews.txt",  sep="\t", header=TRUE) # LOADING MOVIE REVIEWS

### CREATING FACTOR FROM STRING LABELS ###
articles$codefactor[articles$code=="Negative"] <- 0
articles$codefactor[articles$code=="Positive"] <- 1

########################
### MACHINE LEARNING ###
########################

### CREATING DOCUMENT MATRIX FOR ANALYSIS ###
doc_matrix <- create_matrix(articles$text, # DATAFRAME AND VARIABLE CONTAINING TEXT
                            language="english", 
                            removeNumbers=TRUE, # REMOVE NUMBERS FROM TEXT
                            stemWords=TRUE, # STEM WORDS
                            removeSparseTerms=.80) # FILTER TO REMOVE INFREQUENT WORDS (BIGGER = LESS FILTER)

### CREATING CONTAINER TO GUIDE WHICH ARTICLES TO TRAIN MACHINE ON ###
container <- create_container(doc_matrix, # NAME OF DOCUMENT MATRIX
                              articles$codefactor, # DATAFRAME AND VARIABLE CONTAINING LABELS
                              trainSize=1:200, # WHICH ARTICLES TO TRAIN
                              testSize=201:400, # WHICH ARTICLES TO TEST
                              virgin=FALSE) # DATA HAS LABELS


### TRAINING VARIOUS MODELS ###
SVM <- train_model(container,"SVM")
GLMNET <- train_model(container,"GLMNET")
MAXENT <- train_model(container, "MAXENT")
SLDA <- train_model(container,"SLDA")
BOOSTING <- train_model(container,"BOOSTING")
BAGGING <- train_model(container,"BAGGING")
RF <- train_model(container,"RF")
TREE <- train_model(container,"TREE")

### CLASSIFYING REMAINING ARTICLES ###
SVM_CLASSIFY <- classify_model(container, SVM)
GLMNET_CLASSIFY <- classify_model(container, GLMNET)
MAXENT_CLASSIFY <- classify_model(container, MAXENT)
SLDA_CLASSIFY <- classify_model(container, SLDA)
BOOSTING_CLASSIFY <- classify_model(container, BOOSTING)
BAGGING_CLASSIFY <- classify_model(container, BAGGING)
RF_CLASSIFY <- classify_model(container, RF)
TREE_CLASSIFY <- classify_model(container, TREE)

### ANALYTICS OF MACHINE LEARNING METHODS ###
analytics <- create_analytics(container,
                              cbind(SVM_CLASSIFY, SLDA_CLASSIFY,
                                    BOOSTING_CLASSIFY, BAGGING_CLASSIFY,
                                    RF_CLASSIFY, GLMNET_CLASSIFY,
                                    TREE_CLASSIFY,
                                    MAXENT_CLASSIFY))

### ANALYTICS REPORTS ###
summary(analytics)
create_ensembleSummary(analytics@document_summary)