##############################################
##############################################
   ### WEBSCRAPING HTML WITH R WORKSHOP ###
##############################################
##############################################
### MCGILL WEBSCRAPING & TEXT ANALYSIS WORKSHOP ###
### DENVER MCNENEY ###
### denver.mcneney@mcgill.ca ###

rm(list = ls())
getwd()
setwd("")

### PACKAGES TO INSTALL FOR HTML SCRAPING & TEXT ANALYSIS ###

PackagesToInstall <- c("rvest", "dplyr", "SparseM",
                        "devtools", "tm", "ggplot2")

install.packages(PackagesToInstall, repos = "http://cran.r-project.org")

### CALLING PACKAGES THAT WE WILL USE TODAY ###
for (i in PackagesToInstall){
  library(i,character.only = TRUE)
}

### WORDFISH DOWNLOAD (NOT AVAILABLE FROM CRAN) ###
install_github("conjugateprior/austin")
library("austin")

####################################
### SCRAPING STATE OF THE UNIONS ###
####################################

### OBAMA 2016 ###
### http://www.presidency.ucsb.edu/ws/index.php?pid=111174 ###

### INSPECT ELEMENT IN CHROME ###
### TABLE APPEARS TO HAVE CSS SELECTOR OF "displaytext" ###

selector_name <- ".displaytext"
url <- "http://www.presidency.ucsb.edu/ws/index.php?pid=111174"

### SCRAPING THE TABLE OF INTEREST ###
obama2016 <- html_nodes(read_html(url), selector_name) %>%
  html_text()

###############################
### SCRAPING MULTIPLE SOTUs ###
###############################

### WILL SCRAPE LAST 3 PRESIDENTS' SOTUs ###
### ONE PER YEAR, SO NEED DATAFRAME OF 24 ROWS ###
data <- data.frame(matrix(NA, nrow = 24, ncol = 0))
data$years <- seq(1993, 2016) # CREATING YEARS VARIABLE

### LABELING PRESIDENTIAL YEARS ###
data$president[data$years>=2009 & data$years<=2016] <- "Obama"
data$president[data$years>=2001 & data$years<=2008] <- "Bush"
data$president[data$years>=1993 & data$years<=2000] <- "Clinton"

### LABELING PARTY ###
data$party[data$president=="Obama"] <- "Democrat"
data$party[data$president=="Clinton"] <- "Democrat"
data$party[data$president=="Bush"] <- "Republican"
data$party <- as.factor(data$party) # CONVERT TO FACTOR VARIABLE

### ID VARIABLES ###
data$id <- row.names(data) # SIMPLE ID VARIABLE

### CREATING COMPLEX ID VARIABLE ###
data$identifier <- paste(data$president, # PASTE PRESIDENT'S NAME
                         data$years, # PASTE YEAR
                         sep="") # NO SEPARATION BETWEEN TWO STRINGS

##############################################################
    ### SETTING URLS TO SCRAPE (GOT FROM LIST ONLINE) ###
##############################################################

### CREATE LIST OF URLS ###
urls <- c(
    "http://www.presidency.ucsb.edu/ws/index.php?pid=47232",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=50409",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=51634",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=53091",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=53358",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=56280",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=57577",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=58708",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=29643",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=29644",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=29645",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=29646",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=58746",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=65090",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=24446",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=76301",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=85737",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=87433",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=88928",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=99000",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=102826",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=104596",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=108031",
    "http://www.presidency.ucsb.edu/ws/index.php?pid=111174")

### QUICK LOOK AT OTHER WEBSITES SHOWS THE HTML STRUCTURE THE SAME ###
selector_name <- ".displaytext"

#########################################
### LOOPING OVER URLS TO SCRAPE SOTUs ###
#########################################

for (item in seq_along(urls)){ # FOR EACH URL IN LIST
  print(urls[item]) # PRINT URL TO MAKE SURE LOOP IS FUNCTIONING CORRECTLY
  data$text[[item]] <- html_nodes(read_html(urls[item]), # NEED TO SPECIFY TO RECODE FOR EACH ID (COUNTER)
                          # OTHERWISE EACH LOOP WILL RECODE ALL ENTRIES
                          # SAME AS ABOVE, BUT URL IS NOW ``ITEM'' FROM LIST OF URLs
                selector_name) %>%
  html_text()
}

##########################################
      ### BAG OF WORDS ANALYSIS ###
### SENTIMENT ANALYSIS USING LEXICODER ###
##########################################

### LEXICODER.JAR & LSD2015.lc3 SHOULD BE IN WORKING DIRECTORY ###

### LEXICODER REQUIRES A FOLDER CONTAINING EACH UNIT OF ANALYSIS IN A SEPARATE TEXT FILE ###
dir.create("corpus")  # CREATE FOLDER IN WORKING DIRECTORY CALLED ``CORPUS''

### LOOP TO CREATE NEW TEXT FILE FOR EACH ROW IN DATASET ###
L <- length(data$text) # GETTING NUMBER OF TEXT FILES (ROWS) TO CREATE
for (i in 1:L) { # LOOP OVER NUMBER OF ROWS
  t <- data[i,"text"]
  write.table(t, paste("corpus/",i,".txt",sep=""), sep="\t",col.names=F,row.names=F, quote = F) # WRITE TAB DELIMITED FILE WITH ID FOR EACH ROW IN DATAFRAME
}

######################
### PRE-PROCESSING ###
######################
### NOTE! LEXICODER PROCESSING ALTERS FILES PERMANENTLY ###
### PROCESSING:
  ### Converts accents and other characters to plain characters
  ### Converts to lowercase
  ### Removes punctuation ###

system("./lex pre dat=corpus") # NAME OF FOLDER CONTAINING TEXT FILES (IN THIS CASE, ``corpus'')

##################
### WORD COUNT ###
##################

system("./lex wc dat=corpus > wc.txt") # CREATES TEXT FILE NAMED ``wc.txt'' IN WORKING DIRECTORY
                                       # THAT CONTAINS WORD COUNTS OF EACH FILE ID

### IMPORTING WORD COUNT TO R & MERGING W/ EXISTING DATAFRAME ###
wc <- read.table("wc.txt", # NAME OF WORD COUNT FILE
                 header=T, # FILE HAS HEADERS
                 sep="\t") # TAB-DELIMITED

wc$case <- as.numeric(gsub(".txt", "", as.character(wc$case))) # FORMATS ID VARIABLE BY REMOVING ``.TXT''
wc <- wc[order(wc$case),] # SORT DATA ON ID VARIABLE
rownames(wc) <- NULL # REFRESH ROWNAMES
data <- merge(data, # ORIGINAL DATAFRAME
              wc, # WORD COUNT DATAFRAME
              by.x="id", # ORIGINAL DATAFRAME ID VARIABLE
              by.y="case", # WORD COUNT DATAFRAME ID VARIABLE
              all.x=T) 

#####################################
### GETTING POS & NEG WORD COUNTS ###
#####################################

system("./lex dc dat=corpus md=LSD2015.lc3 > dc.txt") # AS BEFORE, ``DAT'' IS FOLDER CONTAINING TXT FILES
                                                      # ``MD'' IS THE LEXICODER SENTIMENT DICTIONARY (IN WORKING DIRECTORY)
                                                      # ``dc.txt'' OUTPUT FILE IN WORKING DIRECTORY THAT CONTAINS ID, # POS WORDS, # NEG WORDS

### IMPORTING DICTIONARY DATA TO R & MERGING W/ EXISTING DATAFRAME ###
dc <- read.table("dc.txt",header=T,sep="\t") # READ INTO R
dc$case <- as.numeric(gsub(".txt", "", as.character(dc$case))) # AS BEFORE, FORMATS ID VAR, MERGES
dc <- dc[order(dc$case),]
rownames(dc) <- NULL
data <- merge(data,dc,by.x="id",by.y="case",all.x=T) 

#############################
### CREATING TONE VARIABLE ##
#############################

### WANT TO STANDARDIZE FOR # OF WORDS ###
data$tone <- ((data$positive - data$negative)/(data$wordcount))*100
### MULTIPLY BY 100 TO MAKE VALUES EASIER TO DIGEST ###
data <- data[order(data$years),]

############################
      ### GRAPHICS ###
############################

### BAR GRAPH ###
ggplot(data, # DATAFRAME
       aes(x=years, # X-AXIS
           y=tone)) + # Y-AXIS
  geom_bar(aes(fill=party),   # COLOUR OF BAR DEPENDS ON VARIABLE ``party''
           stat="identity",
           colour="black") +    # BLACK OUTLINE
  scale_fill_manual(values=c("blue","red")) # CUSTOM FILL COLOURS

### LOESS SMOOTHING ###
ggplot(data, # DATAFRAME
       aes(x=years, # X-AXIS
           y=tone, # Y-AXIS
           color=president, # COLOUR OF MARKERS DEPENDS ON VAR ``president''
           shape=president)) + # SHAPE OF MARKERS DEPENDS ON VAR ``president''
    geom_point() + 
    geom_smooth(method=lm, # LOESS SMOOTHING
                aes(fill=president)) # COLOUR OF LINE AND ERROR BARS DEPENDS ON ``president''

##########################################
  ### ESTIMATING POLITICAL POSITIONS ###
          ### USING WORDFISH ###
##########################################

### WORDFISH REQUIRES TEXT IN TERM-DOCUMENT MATRIX ###

doc.corpus = Corpus(VectorSource(data$text)) 
inspect(doc.corpus)

######################
### PRE-PROCESSING ###
######################

doc.corpus <- tm_map(doc.corpus, content_transformer(tolower), mc.cores=1) # LOWER-CASE
doc.corpus <- tm_map(doc.corpus, removeNumbers, mc.cores=1) # REMOVE NUMBERS
doc.corpus <- tm_map(doc.corpus, removeWords, stopwords("SMART"), mc.cores=1) # REMOVE STOP WORDS
doc.corpus <- tm_map(doc.corpus, removeWords, stopwords("english"), mc.cores=1) # REMOVE STOP WORDS
doc.corpus <- tm_map(doc.corpus, removePunctuation, mc.cores=1) # REMOVE PUNCTUATION
doc.corpus <- tm_map(doc.corpus, stripWhitespace, mc.cores=1) # REMOVE WHITE SPACE

### CONVERT & TRANSPOSE WORD COUNT MATRIX FOR USE WITH WORDFISH ###

wordfreqmatrix <-TermDocumentMatrix(doc.corpus) # CREATING TERM-DOCUMENT MATRIX
wordfreqmatrix <- removeSparseTerms(wordfreqmatrix, # REMOVING SPARSE WORDS
                                    0.5) # FILTER SET TO 0.5

wcdata<-as.matrix(wordfreqmatrix) # CREATING WORD MATRIX

wordfishdata <- wfm(wcdata) # WORD FREQUENCY MATRIX

#####################
### RUNNING MODEL ###
#####################

### WORDFISH REQUIRES ANCHORS OF ENDPOINTS OF DIMENSIONS ###
### IN THIS CASE, WE'LL USE OBAMA 2012 AS LEFT ENDPOINT ###
### AND BUSH 2002 AS RIGHT ENDPOINT ###
results <- wordfish(wordfishdata, # WORD FREQUENCY MATRIX
                    dir=c(20, # COLUMN NUMBER OF ``LEFT'' ANCHOR
                          10)) # COLUMN NUMBER OF ``RIGHT'' ANCHOR

summary(results)

### APPENDING RESULTS TO ORIGINAL DATAFRAME ###
data$score <- results$theta # DOCUMENT POSITION ESTIMATE

### CREATING CONF. INTERVALS
data$scoresehigh <- (results$theta) + 1.96*(results$se.theta)
data$scoreselow <- (results$theta) - 1.96*(results$se.theta)

############################
      ### GRAPHICS ###
############################

x <- ggplot(data, # DATAFRAME OF INTEREST
            aes(x=reorder(identifier, score), # ORDER PLOT ON LEFT-RIGHT SPECTRUM
                y = score, # Y-AXS
                shape=president, # SHAPE OF MARKER DEPENDENT ON PRESIDENT
                colour=president)) + # COLOUR OF MARKER DEPENDENT ON PRESIDENT
  geom_point(stat = "identity") + 
  geom_pointrange(aes(ymin=data$scoreselow, # CREATING CONF. INT.
                      ymax=data$scoresehigh, 
                      colour=data$president)) + # COLOUR OF CONF. INT. DEPENDS ON PRESIDENT
  coord_flip() # DATA LOOKS BETTER WITH X AND Y AXES FLIPPED

x + xlab("") + ylab("Left-Right Scale") + ggtitle("Ideology of State of the Union Speeches - 1993-2016") +
  theme(legend.title=element_blank(), legend.text = element_text(size = 16), 
  plot.title=element_text(face="bold", size=20))

#######################
 ### WORD CLUSTERS ###
   ### FRAMING? ###
#######################

wordfreqmatrix2 <-TermDocumentMatrix(doc.corpus)
wordfreqmatrix2 <- removeSparseTerms(wordfreqmatrix2, 0.02)

wordcluster<-as.matrix(wordfreqmatrix2)

distMatrix <- dist(scale(wordcluster))
fit <- hclust(distMatrix, method = "ward")
plot(fit)

#####################################
### LAB EXERCISE ###
#####################################

### LIST OF INAUGURAL ADDRESSES ###
### BEGINS WITH FDR (1933) & ENDS ###
### WITH TRUMP (2017) ###
### 22 TOTAL ADDRESSES (1 EVERY 4 YEARS) ###

labdata <- data.frame(matrix(NA, nrow = 22, ncol = 0))
labdata$years <- seq(1933, 2017, by = 4) # CREATING YEARS VARIABLE

laburls <- c(
  "http://www.presidency.ucsb.edu/ws/index.php?pid=14473",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=15349",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=16022",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=16607",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=13282",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=9600",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=10856",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=8032",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=26985",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=1941",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=4141",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=6575",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=43130",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=38688",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=16610",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=46366",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=54183",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=25853",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=58745",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=44",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=102827",
  "http://www.presidency.ucsb.edu/ws/index.php?pid=120000")

labdata$id <- row.names(labdata) # SIMPLE ID VARIABLE

labdata$president[labdata$years==2017] <- "Trump"
labdata$president[labdata$years>=2009 & labdata$years<=2016] <- "Obama"
labdata$president[labdata$years>=2001 & labdata$years<=2008] <- "GBush"
labdata$president[labdata$years>=1993 & labdata$years<=2000] <- "Clinton"
labdata$president[labdata$years>=1989 & labdata$years<=1992] <- "HBush"
labdata$president[labdata$years>=1981 & labdata$years<=1988] <- "Reagan"
labdata$president[labdata$years>=1977 & labdata$years<=1980] <- "Carter"
labdata$president[labdata$years>=1969 & labdata$years<=1976] <- "Nixon"
labdata$president[labdata$years>=1965 & labdata$years<=1968] <- "Johnson"
labdata$president[labdata$years>=1961 & labdata$years<=1964] <- "Kennedy"
labdata$president[labdata$years>=1953 & labdata$years<=1960] <- "Eisenhower"
labdata$president[labdata$years>=1949 & labdata$years<=1952] <- "Truman"
labdata$president[labdata$years>=1933 & labdata$years<=1948] <- "Roosevelt"

### CREATING COMPLEX ID VARIABLE ###
labdata$identifier <- paste(labdata$president, # PASTE PRESIDENT'S NAME
                            labdata$years, # PASTE YEAR
                            sep="") # NO SEPARATION BETWEEN TWO STRINGS
