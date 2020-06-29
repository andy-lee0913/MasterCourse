// Learn more about F# at https://fsharp.org

open System
open FSharp.Data
open FSharp.Text.RegexProvider

open PuppeteerSharp

// CSV Schema that will be used for output later
type ItemInfo =
    CsvProvider<Sample = "Label,  Stars, Ratings, Sold, PriceMin, PriceMax, Stock, Seller, SellerRatings, Products, ResponseRate, ResponseTime, Joined, Followers, URL",
                Schema = "string, float, int,     int,  float,    float,    int,   string, int,           int,      float,        string,       string, float,     string",
                HasHeaders = true>

// Type filter RegEx
type Stock = Regex<(@"(?<Stock>^\d+).piece")>
type Price = Regex<(@"(?<Price>^RM.*\.\d{2})")>
type PriceRange = Regex<(@"(?<PriceMin>^RM.*\.\d{2}).+(?<PriceMax>RM.*\.\d{2})")>

// Get the HTNL data from an AliExpress listing
let GetShListing (browser :Browser) (url :string) = async {   
    // Simulate user browsing activity to load the similar items listing
    use! page = browser.NewPageAsync () |> Async.AwaitTask
    do! page.GoToAsync (url, WaitUntilNavigation.Networkidle0) |> Async.AwaitTask |> Async.Ignore
    do! page.ClickAsync "button.shopee-button-outline" |> Async.AwaitTask |> Async.Ignore
    //do! page.ClickAsync "div[class='shopee-sort-by-options__option']" |> Async.AwaitTask |> Async.Ignore
    do! page.EvaluateExpressionAsync "window.scrollBy(0, document.body.scrollHeight);" |> Async.AwaitTask |> Async.Ignore
    do! page.WaitForSelectorAsync "footer" |> Async.AwaitTask |> Async.Ignore

    // Return the HTML data captured by the browser
    return! page.GetContentAsync () |> Async.AwaitTask
}

let GetShItemInfo (browser :Browser) (url :string) = async {   
    // Simulate user browsing activity to load item data
    use! page = browser.NewPageAsync () |> Async.AwaitTask
    do! page.GoToAsync (url, WaitUntilNavigation.Networkidle0) |> Async.AwaitTask |> Async.Ignore
    //do! page.ClickAsync "button.shopee-button-outline" |> Async.AwaitTask |> Async.Ignore
    do! page.ClickAsync "div._3Lybjn" |> Async.AwaitTask |> Async.Ignore
    do! page.EvaluateExpressionAsync "window.scrollBy(0, document.body.scrollHeight);" |> Async.AwaitTask |> Async.Ignore
    do! page.WaitForSelectorAsync "footer" |> Async.AwaitTask |> Async.Ignore

    // Return the HTML data captured by the browser
    return (page.GetContentAsync () |> Async.AwaitTask |> Async.RunSynchronously, url)
}

let GetItemURLs output =
    Seq.map HtmlDocument.Parse output
    |> Seq.collect (fun x -> x.CssSelect @"a[data-sqe='link']")
    |> Seq.map (fun x -> @"https://shopee.com.my" + x.AttributeValue("href"))

let CharStrip (str :string) = str |> Seq.filter (fun c -> Char.IsNumber c || c = '.') |> Array.ofSeq |> String

let PriceMin price =
    let sprice = match price with
                 | pm when PriceRange().IsMatch(pm) -> PriceRange().TypedMatch(pm).PriceMin.Value                                          
                 | pv when Price().IsMatch(pv) -> Price().TypedMatch(pv).Price.Value
                 | p -> p
    sprice |> CharStrip |> float

let PriceMax price =
    let sprice = match price with
                 | pm when PriceRange().IsMatch(pm) -> PriceRange().TypedMatch(pm).PriceMax.Value
                 | pv when Price().IsMatch(pv) -> Price().TypedMatch(pv).Price.Value
                 | p -> p
    sprice |> CharStrip |> float

let StockFilter (node :List<HtmlNode>) =
    let y = node |> Seq.map (fun x -> x.InnerText().Trim ())
    Stock().TypedMatch(Seq.item 2 y).Stock.Value

let GetItemData (output, url)  = async {
    let doc = HtmlDocument.Parse output
    let label = doc.CssSelect ("div[class='qaNIZv'] > span") |> List.map (fun x -> x.InnerText().Trim ())
    let stars = doc.CssSelect ("div[class='_3Oj5_n _2z6cUg']") |> List.map (fun x -> x.InnerText().Trim () |> float)
    let ratings = doc.CssSelect ("div[class='_3Oj5_n']") |> List.map (fun x -> x.InnerText().Trim ())
    let sold = doc.CssSelect ("div[class='_22sp0A']") |> List.map (fun x -> x.InnerText().Trim ())
    let price = doc.CssSelect ("div[class='_3n5NQx']") |> List.map (fun x -> x.InnerText().Trim ())
    let stock = doc.CssSelect ("div.flex.items-center._1FzU2Y > div > div div") |> StockFilter |> int
    let seller = doc.CssSelect ("div[class='_3Lybjn']") |> List.map (fun x -> x.InnerText().Trim ())
    let sinfo = doc.CssSelect ("span._1rsHot") |> List.map (fun x -> x.InnerText().Trim ())
    let price1 = PriceMin price.Head
    let price2 = PriceMin price.Head
    
    let _ratings = (if ratings.IsEmpty then 0 else (if ratings.Head.Contains('k') then (int ((ratings.Head |> CharStrip |> float) * 1000.0)) else int ratings.Head))
    let _sratings = (if sinfo.[0].Contains('k') then (int ((sinfo.[0] |> CharStrip |> float) * 1000.0)) else int sinfo.[0])
    let _followers = (if sinfo.[5].Contains('k') then ((sinfo.[5] |> CharStrip |> float) * 1000.0) else float sinfo.[5])
    let _sold = (if sold.Head.Contains('k') then (int ((sold.Head |> CharStrip |> float) * 1000.0)) else int sold.Head)
    let _products = (if sinfo.[1].Contains('k') then (int ((sinfo.[1] |> CharStrip |> float) * 1000.0)) else int sinfo.[1])

    return ItemInfo.Row(
        label.Head,
        (if stars.IsEmpty then 0.0 else stars.Head),
        _ratings,
        _sold,
        price1,
        price2,
        stock,
        seller.Head,
        _sratings,
        _products,
        (sinfo.[2] |> CharStrip |> float) / 100.0,
        sinfo.[3].Remove(0, 7),
        sinfo.[4].Remove(sinfo.[4].IndexOf("ago")),
        _followers,
        url)
}

[<EntryPoint>]
let main argv =
    match argv.Length with
    | 3 -> printfn "\n\tDownloading Shopee listing data:"
           printfn "\t%s" argv.[0]
           let range = (int argv.[1]) - 1
           let pages = [for i in [0..range] -> sprintf "%s?sortBy=ctime&Page=%d" argv.[0] i]

           // Download the Puppeteer Chrome browser
           BrowserFetcher().DownloadAsync BrowserFetcher.DefaultRevision
           |> Async.AwaitTask |> Async.Ignore |> Async.RunSynchronously

           // Set viewport and launch options
           let voptions = ViewPortOptions (Width = 1240, Height = 3570)
           let loptions = LaunchOptions (DefaultViewport = voptions, Headless = true)
           // Launch a browser instance
           use browser = Puppeteer.LaunchAsync loptions |> Async.AwaitTask |> Async.RunSynchronously

           // Get a list of items from the product/service category
           let output = (pages |> Seq.map (fun x -> GetShListing browser x), 4) |> Async.Parallel 
                        |> Async.RunSynchronously

           // Parse the HTML data and extract the item urls
           printfn "\tParsing HTML for Item listings..."
           let uris = GetItemURLs output
                
           // Get each and every item HTML data
           printfn "\tDownloading Shopee listing HTML..."
           let output = (uris |> Seq.map (fun x -> GetShItemInfo browser x), 4) |> Async.Parallel |> Async.RunSynchronously
           
           // Close the browser
           browser.CloseAsync () |> Async.AwaitTask |> Async.Start

           // Parse the HTML data and extract the item urls
           printfn "\tGenerating CSV data from item listing..."
           let csv = new ItemInfo (output |> Seq.map GetItemData |> Async.Parallel |> Async.RunSynchronously)
           
           // Save the generated CSV output into a file
           printfn "\tSaving output into: %s" argv.[2]
           csv.Save(argv.[2])

    | _ -> printfn "\tURL, Number of Pages and CSV file name required."
           printfn "\tExample: dotnet run https://shopee.com.my/Tickets-Vouchers-cat.173 100 output.csv"
    0 // return an integer exit code
