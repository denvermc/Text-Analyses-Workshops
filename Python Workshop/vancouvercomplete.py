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

### SEARCH FIELDS ###
browser.find_element_by_xpath('/html/body/div/div[3]/div[1]/blockquote/form/div/fieldset/table[1]/tbody/tr[3]/td[1]/p/input[3]').click() # CLICK ON CHECKBOX "City Council Meetings and Agendas"
browser.find_element_by_name('tx0').send_keys('Environment') # FIND SEARCHBOX AND INSERT SEARCH TERMS
browser.find_element_by_css_selector('input[type="radio"][value="ba"]').click() # CLICK RADIO BUTTON TO SEARCH SPECIFIC DATES
browser.find_element_by_name('ady').clear() # FIND "ON OR AFTER" DAY FIELD AND CLEAR CONTENTS
browser.find_element_by_name('ady').send_keys('01') # ENTER "01" AS DAY
browser.find_element_by_xpath('//*[@id="after"]/option[@value="3"]').click() # CLICK MONTH DROPDOWN MENU FOR "MARCH"
time.sleep(1) # SLEEP 1 SECOND
browser.find_element_by_name('ayr').clear() # FIND "ON OR AFTER" YEAR FIELD AND CLEAR CONTENTS
browser.find_element_by_name('ayr').send_keys('2015') # ENTER "2015" AS YEAR
browser.find_element_by_name('bdy').clear() # FIND "ON OR BEFORE" DAY FIELD AND CLEAR CONTENTS
browser.find_element_by_name('bdy').send_keys('31') # ENTER "31" AS DAY 
browser.find_element_by_xpath('//*[@id="before"]/option[@value="12"]').click() # CLICK MONTH DROPDOWN MENU FOR "DEC"
time.sleep(1) # SLEEP 1 SECOND
browser.find_element_by_name('byr').clear() # FIND "ON OR BEFORE" YEAR FIELD AND CLEAR CONTENTS
browser.find_element_by_name('byr').send_keys('2015') # ENTER "2015" AS YEAR
browser.find_element_by_xpath('//*[@id="show"]/option[@value="500"]').click() # CLICK "# RESULTS" DROPDOWN AND SELECT "500"
browser.find_element_by_xpath('//*[@id="show"]/option[@value="1"]').click() # SORT RESULTS BY DATE 
time.sleep(1) # SLEEP 1 SECOND
browser.find_element_by_name('submit').click() # CLICK "SEARCH" BUTTON

### DOWNLOADING RETURNED FILES ###
links = browser.find_elements_by_partial_link_text('Agenda') # GET LIST OF LINKS THAT CONTAIN ``Agenda''
listofurls = [eachlink.get_attribute("href") for eachlink in links] # TRANSPOSE LIST OF ELEMENTS TO LIST OF LINKS

for pageurls in listofurls: # SIMPLE LOOP, FOR EACH LINK IN OUR LIST, DO THE BELOW
	browser.get(pageurls) # GO TO SUBPAGE FOR EACH MEETING
	time.sleep(5) # PAUSE FOR 5 SECONDS
	browser.find_element_by_partial_link_text("Minutes ").click() # CLICK ON LINK CONTAINING TEXT
	time.sleep(5) # PAUSE FOR 5 SECONDS


