##############################################
##############################################
        ### WORKING WITH TWITTER ###
##############################################
##############################################
### MCGILL WEBSCRAPING & TEXT ANALYSIS WORKSHOP ###
### DENVER MCNENEY ###
### denver.mcneney@mcgill.ca ###

rm(list = ls()) # REMOVE ALL ITEMS FROM WORKSPACE

### SETTING WORKING DIRECTORY ###
getwd()
setwd("") # INSERT YOUR WORKING DIRECTORY IF NEEDED

### INSTALLING PACKAGES THAT WE WILL USE TODAY ###
PackagesToInstall <- c("streamR","ROAuth","twitteR","ggplot2","devtools", 
                       "RCurl", "wordcloud", "tm")

### UNCOMMENT LINE BELOW IF YOU HAVE *NOT* INSTALLED PACKAGES ALREADY ###
# install.packages(PackagesToInstall, repos = "http://cran.r-project.org")

### CALLING PACKAGES THAT WE WILL USE TODAY ###
for (i in PackagesToInstall){
  library(i,character.only = TRUE)
}

### NEED TO DOWNLOAD SOURCE VERSION ###
### OF GGMAP SINCE NEW VERSION DOES ###
### NOT COEXIST WITH GGPLOT2 UPDATE ###

install_github("dkahle/ggmap")
library('ggmap')

### IF USING WINDOWS ###
### install.packages("base64enc")
### library("base64enc")

##############################################
  ### SETTING UP TWITTER OAuth HANDSHAKE ###
##############################################
### YOU ONLY NEED TO RUN THIS SECTION ONCE ###
##############################################

requestURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"
consumerKey <- "" # INSERT YOUR CONSUMER KEY HERE
consumerSecret <- "" # INSERT YOUR CONSUMER SECRET HERE
access_token = "" # INSERT YOUR ACCESS TOKEN 
access_token_secret = "" # INSERT YOUR ACCESS TOKEN SECRET 


### SETTING UP OAUTH ###
### FOR RESTful API ###
my_oauth <- setup_twitter_oauth(consumer_key = consumerKey,
                                consumer_secret = consumerSecret,
                                access_token = access_token,
                                access_secret = access_token_secret)

### SAVE OAuth TOKEN FOR FUTURE USE ###
save(my_oauth, file="my_oauth")

### SETTING UP OAUTH ###
### FOR STREAMING API ###

my_oauth2 <- OAuthFactory$new(consumerKey = consumerKey,
                              consumerSecret = consumerSecret,
                              requestURL = requestURL,
                              accessURL = accessURL,
                              authURL = authURL)

my_oauth2$handshake(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
save(my_oauth2, file="my_oauth2")

##############################################
  ### GET ALL TWEETS FROM SPECIFIC USER ###
##############################################
load("my_oauth") # LOAD OAuth ENVIRONMENT
use_oauth_token(my_oauth)

trumptweets <- userTimeline("realdonaldtrump", # TWITTER HANDLE OF PERSON TO SCRAPE
                            n=3200, # 3,200 TWEETS IS RESTful TWITTER API LIMIT
                            includeRts=TRUE, # WHETHER OR NOT TO INCLUDE RETWEETS
                            excludeReplies=FALSE, # WHETHER OR NOT TO *EXCLUDE* REPLIES
                            retryOnRateLimit=180) # NUMBER OF TIMES TO RETRY SEARCH IF RATE-LIMIT EXPERIENCED

### CONVERTING LIST OF TWEETS TO DATAFRAME ###
tweetsDT <- twListToDF(trumptweets)

##############################################
### ACCESS LIVE TWITTER STREAM W/ SPECIFIC ###
         ### KEYWORDS & SEARCHES ###
##############################################

filterStream(file.name = "tweets.json", # SAVE TWEETS IN JSON FORMAT
             track = c("Clinton", "Democrat"), # SEARCH TERMS
             language = "en", # ENGLISH TWEETS
             timeout = 60, # KEEP CONNECTION ALIVE FOR 60 SECONDS
             oauth = my_oauth2) # USE EXISTING OAuth FILE

### PARSING .JSON FILE TO DATAFRAME ###
### NUMBER OF TWEETS PARSED MAY NOT BE SAME AS ###
### NUMBER OF TWEETS COLLECTED DUE TO RETWEETS ###

tweets.df <- parseTweets("tweets.json", simplify = FALSE) # PARSE TWEETS

###########################
### WORDCLOUD OF TWEETS ###
###########################
### NEED TO GET RID OF WEIRD TWITTER CHARACTERS ###
### I.E. EMOJIS OR OTHER ODD ENCODINGS ###
tweetsDT$text <- iconv(tweetsDT$text,to="utf-8-mac")
tweetsDT$text <- gsub('\\p{So}|\\p{Cn}', '', tweetsDT$text, perl = TRUE)

### CONVERT TWEETS TO CORPUS AND DO SOME TRANSFORMATIONS ###
mach_corpus = Corpus(VectorSource(tweetsDT$text))
mach_corpus <- tm_map(mach_corpus, removePunctuation)
mach_corpus <- tm_map(mach_corpus, removeWords, stopwords('english'))
mach_corpus <- tm_map(mach_corpus, stripWhitespace)

### PLOT WORDCLOUD ###
wordcloud(mach_corpus, # CORPUS NAME
          scale=c(3,0.2), # SIZE OF BIGGEST AND SMALLEST WORDS
          max.words = 100, # TOTAL NUMBER OF WORDS
          random.order = FALSE, # PLOT IN DECREASING FREQUENCY
          colors=brewer.pal(8, "Dark2")) # GOOD COLOUR SCHEME


##############################################
### ACCESS LIVE TWITTER STREAM W/ SPECIFIC ###
        ### GEOCODED MATERIAL ###
##############################################

### REMEMBER: LESS THAN 1% OF TWEETS ARE GEOCODED ###
### NEED ``BOUNDING BOX'' OF AREA TO SEARCH ###
### BOUNDING BOX INFORMATION AVAILABLE AT ###
  ### http://boundingbox.klokantech.com/ ###

### CAPTURING TWEETS FROM MONTREAL ###

filterStream(file.name="tweets_montreal.json", # NAME OF FILE STORING SAVED TWEETS
             locations=c(-73.986345, # BEGIN WITH SOUTHWEST CORNER (LONGITUDE)
                         45.394111, # SOUTHWEST CORNER (LATITUDE)
                         -73.432617, # NORTHEAST CORNER (LONGITUDE)
                         45.718166), # NORTHEAST CORNER (LATITUDE)
             language = c("en","fr"), # ENGLISH & FRENCH TWEETS
             timeout=30, # KEEP CONNECTION ALIVE FOR 30 SECONDS
             oauth=my_oauth2) # USE EXISTING OAuth FILE

### PARSING .JSON FILE TO DATAFRAME ###
tweets.montreal <- parseTweets("tweets_montreal.json", verbose = TRUE)

### GIVING SIMPLE ID FOR EACH TWEET ###
tweets.montreal$id <- 1:nrow(tweets.montreal)
##############################################
     ### PLOTTING GEOCODED TWEETS ###
##############################################

### EXTRACTING LONG/LAT FROM TWEETS ###
points <- data.frame(x = as.numeric(tweets.montreal$lon), y = as.numeric(tweets.montreal$lat), id = tweets.montreal$id)
points <- points[points$y != 0 & points$x != 0, ] # deleting tweets sent from (0,0) coordinates (probably errors)

### PLOTTING TWEETS ON MAP ###

montreal <- get_map(location = "Ile de Montreal, QC", zoom = 11) # GOOGLE MAP DATA (Can try any area or point of reference)

ggmap(montreal) + # BASE MAP OF MONTREAL
  geom_point(data = points, # DATAFRAME CONTAINING POINTS
      aes(x = x, # X COORDINATE VARIABLE NAME
          y = y # Y COORDINATE VARIABLE NAME
          ), size = 2, # SIZE OF MARKER
      alpha = .5, # TRANSPARENCY OF MARKER
      color = "black") # COLOUR OF MARKER

################
### HEAT MAP ###
################

ggmap(montreal) + # BASE MAP OF montreal
  geom_density2d(data = points, # DATAFRAME CONTAINING POINTS
  aes(x = x, # X COORDINATE VARIABLE NAME
      y = y), # Y COORDINATE VARIABLE NAME
  size = 0.3) + # SIZE OF MARKER
  stat_density2d(data = points, # DATAFRAME CONTAINING POINTS
  aes(x = x, # X COORDINATE VARIABLE NAME
      y = y, # Y COORDINATE VARIABLE NAME
      fill = ..level.., alpha = ..level..), size = 0.01, 
  geom = "polygon") + scale_fill_gradient(low = "green", # COLOUR FOR LOW DENSITY
                                          high = "red") + # COLOUR FOR HIGH DENSITY
  scale_alpha(range = c(0, 0.3), guide = FALSE)

###################################################
### NUMBER OF TWEETS BY MONTREAL NEIGHBOURHOOD ###
###################################################

### DOWNLOAD NEIGHBOURHOOD SHAPE FILE (SHP) FROM ###
### http://data.montreal.ca/datacatalogue/localAreaBoundary.htm ###

### MAC USERS NEED TO DO SOME DOWNLOADING FIRST ###
### INSTALL GDAL (http://www.kyngchaos.com/files/software/frameworks/GDAL_Complete-1.11.dmg) ###
### IN TERMINAL, ENTER: /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" ###
### IN TERMINAL, ENTER: brew install gdal ###

### PACKAGES REQUIRED FOR PLOTTING WITH SHAPEFILES ###
GeographicPackages <- c("rgdal", "maptools", "rgeos", "gpclib", "splancs", "plyr")

install.packages(GeographicPackages, repos = "http://cran.r-project.org")

### CALLING PACKAGES THAT WE WILL USE TODAY ###
for (i in GeographicPackages){
  library(i,character.only = TRUE)
}

### INPUTTING SHAPEFILES ###
gpclibPermit() # WORKAROUND TO ERROR IN RGDAL
neighbourhood <- readOGR(dsn = ".", # FOLDER WHERE SHAPEFILES DOWNLOADED. LEAVE LIKE THIS IF IN WORKING DIR
                         layer = "boroughs_and_munis") # NAME OF SHAPEFILES
names(neighbourhood@data)[1] <- "id" # RENAMING `NOM' TO `id'
neighbourhood <- spTransform(neighbourhood, CRS("+proj=longlat +datum=WGS84")) # TRANSFORMING COORDINATES TO SAME AS THOSE OF TWEETS
neighbourhood <- fortify(neighbourhood, # NAME OF SHAPEFILE OBJECT
                         region="id") # ID VARIABLE OF NEIGHBOURHOODS

montreal <- get_map(location = "Ile de Montreal, QC", zoom = 11) # GOOGLE MAP DATA (Can try any area or point of reference)

### PLOTTING TWEETS WITH NEIGHBOURHOOD OVERLAY ###
ggmap(montreal) + # GOOGLE MAP DATA FROM BEFORE
  geom_polygon(aes(x = long, # NAME OF LONG. VARIABLE IN ``NEIGHBOURHOOD''
                   y = lat, # NAME OF LAT. VARIABLE IN ``NEIGHBOURHOOD'
                   group = group), # NAME OF LONG. VARIABLE IN ``NEIGHBOURHOOD'
               data = neighbourhood, # NAME OF NEIGHBOURHOOD SHAPEFILE DATAFRAME
               size = 1, # SIZE OF BORDERLINES
               colour = "black", # COLOUR OF BORDERLINES
               fill=NA) + # FILL COLOUR OF NEIGHBOURHOODS
  geom_point(data = points, # PLOTTING POINTS (AS BEFORE)
             aes(x = x, y = y), size = 5, alpha = .5, color = "black")

##########################################
### NUMBER OF TWEETS PER NEIGHBOURHOOD ###
##########################################

### FIRST NEED TO PLACE TWEET COORDINATES IN NEIGHBOURHOODS ###

### RGDAL REQUIRES US TO GET RID OF 'NA' VALUES IN COORDINATES ###
points2 <- points[!rowSums(is.na(points[1:2])), ]
coordinates(points2)<-~x+y # CLASSIFYING DATAFRAME AS COORDINATES
neighbourhood2 <- readOGR(dsn = ".", layer = "boroughs_and_munis") # READING IN SHAPEFILES AGAIN (LONG STORY)
neighbourhood2 <- spTransform(neighbourhood2, CRS("+proj=longlat +datum=WGS84"))
names(neighbourhood2@data)[1] <- "id"

proj4string(points2) <- proj4string(neighbourhood2) # TELLING R THAT COORDINATE SYSTEMS ARE THE SAME FOR NEIGHBOURHOOD FILES AND TWEET COORDINATES
neighbourhoodinfo <- over(points2, neighbourhood2) # WHICH COORDINATES ARE IN WHICH SHAPEFILE NEIGHBOURHOOD
names(neighbourhoodinfo)[1] <- "NAME"
neighbourhoodinfo$id <- rownames(neighbourhoodinfo) # MAKING ID VARIABLE AGAIN

# MERGING NEIGHBOURHOODINFO WITH ORIGINAL TWEET DATAFRAME
tweets.montreal <- merge(tweets.montreal, # FIRST DATAFRAME
                          neighbourhoodinfo, # SECOND DATAFRAME
                          by.x="id", # NAME OF FIRST DATAFRAME ID VARIABLE
                          by.y="id", # NAME OF SECOND DATAFRAME ID VARIABLE
                          all.x=T) 
# GETTING NUMBER OF TWEETS PER NEIGHBOURHOOD #
neighbourhoodaggregate <- ddply(tweets.montreal, # DATAFRAME TO ANALYSE
                                ~NAME, # GROUPING VARIABLE
                                summarise,
                                numberoftweets # NAME OF NEW VARIABLE
                                =length(id)) # FUNCTION
# RENAMING ID VARIABLE IN AGGREGATE DATAFRAME TO MATCH NEIGHBOURHOOD SHAPEFILE ID #
colnames(neighbourhoodaggregate)[colnames(neighbourhoodaggregate)=="NAME"] <- "id"

# SHAPEFILE TO DATAFRAME #
neighbourhood2 <- fortify(neighbourhood2, # NAME OF SHAPEFILE OBJECT
                         region="id") # ID VARIABLE OF NEIGHBOURHOODS

# MERGING NEIGHBOURHOOD INFO WITH NEIGHBOURHOOD SHAPEFILE #
plotData <- left_join(neighbourhood2, neighbourhoodaggregate)
plotData[is.na(plotData)] <- 0

# FOR PLOTTING, WANT CENTER OF EACH NEIGHBOURHOOD #
cnames <- aggregate(cbind(long, lat, numberoftweets) ~ id, data=plotData, 
                    FUN=function(x)mean(range(x)))

ggmap(montreal) + # BASE MAP OF montreal
  geom_polygon(aes(fill = numberoftweets, # COLOUR WILL BE NUMBER OF TWEETS
                   x = long, # NAME OF LONG. VARIABLE IN ``plotData''
                   y = lat, # NAME OF LAT. VARIABLE IN ``plotData''
                   group = group), # NAME OF GROUPING VARIABLE IN ``plotData''
               data = plotData, # DATA FRAME OF INTEREST
               alpha = 0.8, # TRANSPARENCY OF MARKER
               color = "black", # COLOUR OF MARKER
               size = 0.2) + # SIZE OF MARKER
  scale_fill_gradient(low = "green", # COLOUR FOR LOW DENSITY
                        high = "red") + # COLOUR FOR HIGH DENSITY
  geom_text(data=cnames, # LABELING DATASET
            aes(long, # NAME OF LONG. VARIABLE IN ``cnames''
                lat, # NAME OF LAT. VARIABLE IN ``cnames''
                label = id), # LABEL VARIABLE IN ``cnames'' (IF WANT NEIGHBOURHOOD LABEL USE ``id'')
            size=5, # SIZE OF LABEL
            check_overlap = TRUE) # CHECK FOR LABEL OVERLAP


###################################################
              ### LAB EXERCISE ###
            ### IF TIME PERMITS ###
###################################################
### AMERICA COORDINATES ###
### -125.18, 24.79; -59.5, 48.94 ###




