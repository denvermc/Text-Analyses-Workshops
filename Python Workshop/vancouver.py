import selenium
import os
from selenium import webdriver
import time
import requests
from selenium.webdriver.chrome.options import Options

### SETTING UP CHROMEDRIVER PREFERENCES TO AUTODOWNLOAD PDFs ###
chrome_profile = webdriver.ChromeOptions()
profile = {'download.default_directory': '/Users/dmcneney/Desktop/Vancouver', # WHERE TO DOWNLOAD FILES ON YOUR COMPUTER
           'download.prompt_for_download': False, # AUTO-DOWNLOAD
           'download.directory_upgrade': True,
           'plugins.plugins_disabled': ['Chrome PDF Viewer']} # DISABLE CHROME'S INTERNAL PDF VIEWER
chrome_profile.add_experimental_option('prefs', profile) # BIND NEW PREFERENCES TO CHROMEDRIVER
chrome_profile.add_argument('--disable-extensions')
browser = webdriver.Chrome(executable_path='/Users/dmcneney/Desktop/chromedrivermac', # WHERE CHROMEDRIVER APP LOCATED ON YOUR COMPUTER
                               chrome_options=chrome_profile)
browser.implicitly_wait(30) # WAIT 30 SECONDS BEFORE CALLING AN ERROR (CAN OFTEN TAKE A WHILE TO LOAD PAGES)

                               
### WEBSITE WE WANT TO SCRAPE ###
url = 'http://former.vancouver.ca:8765/advanced/'
browser.get(url) # GO TO WEBSITE WE SPECIFIED ABOVE
time.sleep(2) # SLEEP 2 SECONDS
