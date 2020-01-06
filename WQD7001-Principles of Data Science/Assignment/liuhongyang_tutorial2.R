library(xml2)
library(rvest)
library(stringr)

url2 <- 'https://www.amazon.in/OnePlus-Mirror-Black-64GB-Memory/dp/B0756Z43QS?tag=googinhydr18418-21&tag=googinkenshoo-21&ascsubtag=aee9a916-6acd-4409-92ca-3bdbeb549f80'
url <- 'https://www.amazon.in/Test-Exclusive-608/dp/B07HGBMJT6?ref_=ast_bbp_dp'
webpage <- read_html(url)

title_html <- html_nodes(webpage,'h1#title')

title<-html_text(title_html)

title<-str_replace_all(title,"[\r\n]","")
title<-str_trim(title)
head(title)


#Price of the Product

price_html <- html_nodes(webpage,'#priceblock_dealprice_row')
price <- html_text(price_html)
price <- str_replace_all(price,"[\r\n\t]","")

price <- str_replace_all(price,"[FREEDelivery.Details]","")
price <- str_replace_all(price,"DealPrice","")
price <- str_replace_all(price," ","")
price <- str_trim(price)
head(price)

#Product description
desc_html <- html_nodes(webpage,'div#productDescription')
desc <- html_text(desc_html)
desc <- str_replace_all(desc,"[\r\n\t]","")
desc <- str_trim(desc)
head(desc)


#Rating of the product
rate_html<-html_nodes(webpage,'span#acrPopover')
rate<-html_text(rate_html)
rate<- str_replace_all(rate,"[\r\n\t]","")
rate<- str_trim(rate)
head(rate)


#Size of the product
size_html <- html_nodes(webpage, 'div#variation_size_name')
size_html <- html_nodes(size_html, 'span.selection')
size <- html_text(size_html)
size<-str_replace_all(size, "[\r\n]" , "")
size<- str_trim(size)
head(size)

#Color of the product
color_html <- html_nodes(webpage, 'div#variation_color_name')
color_html <- html_nodes(color_html, 'span.selection')
color <- html_text(color_html)
color<-str_trim(color)
head(color)

#combine them

product_data<- data.frame(Title=title,Price=price,Description=desc,Rating=rate,Size=size,Color=color)

data.frame(product_data)


#Store data in JSON format
library(jsonlite)
json_data <- toJSON(product_data)
cat(json_data)


