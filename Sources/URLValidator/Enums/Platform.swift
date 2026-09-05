//
//  Platform.swift
//  URLValidator
//
//  Created by David Sherlock on 2026.
//
//  Every service a URL can be recognised as. The raw value is the display
//  name. Domains, category and retired status live in one table —
//  Support/PlatformDomains.swift — so they cannot drift apart, and a test
//  checks that every case below appears there exactly once.
//

import Foundation
import URLCore

/// A service a URL belongs to.
public enum Platform: String, CaseIterable, Sendable, Codable {

    // MARK: Video
    case youtube = "YouTube", youtubeMusic = "YouTube Music", youtubeShorts = "YouTube Shorts"
    case youtubeStudio = "YouTube Studio", vimeo = "Vimeo", dailymotion = "Dailymotion"
    case twitch = "Twitch", kick = "Kick", rumble = "Rumble", bitchute = "BitChute", odysee = "Odysee"
    case peertube = "PeerTube", dtube = "DTube", veoh = "Veoh", metacafe = "Metacafe"
    case brighteon = "Brighteon", banned = "Banned.video", rokfin = "Rokfin", floatplane = "Floatplane"
    case nebula = "Nebula", lbry = "LBRY"

    // MARK: Short-form
    case tiktok = "TikTok", instagram = "Instagram", instagramReels = "Instagram Reels"
    case snapchat = "Snapchat", douyin = "Douyin", kuaishou = "Kuaishou", likee = "Likee"
    case triller = "Triller", byte = "Byte", clash = "Clash"

    // MARK: Audio
    case spotify = "Spotify", appleMusic = "Apple Music", applePodcasts = "Apple Podcasts"
    case soundcloud = "SoundCloud", bandcamp = "Bandcamp", deezer = "Deezer", tidal = "Tidal"
    case amazonMusic = "Amazon Music", pandora = "Pandora", audiomack = "Audiomack", qobuz = "Qobuz"
    case mixcloud = "Mixcloud", beatport = "Beatport", napster = "Napster", iheartradio = "iHeartRadio"
    case tunein = "TuneIn", anghami = "Anghami", gaana = "Gaana", jiosaavn = "JioSaavn"
    case lastfm = "Last.fm", genius = "Genius", discogs = "Discogs", musicbrainz = "MusicBrainz"
    case audius = "Audius", ntsRadio = "NTS", shazam = "Shazam", audible = "Audible"

    // MARK: Podcasts
    case anchor = "Anchor", pocketCasts = "PocketCasts", overcast = "Overcast", castbox = "Castbox"
    case googlePodcasts = "Google Podcasts", stitcher = "Stitcher", podbean = "Podbean"
    case buzzsprout = "Buzzsprout", podcastsSpotify = "Spotify for Creators"
    case podcastAddict = "Podcast Addict", castro = "Castro"

    // MARK: Social
    case facebook = "Facebook", twitter = "Twitter/X", linkedin = "LinkedIn", reddit = "Reddit"
    case pinterest = "Pinterest", tumblr = "Tumblr", mastodon = "Mastodon", threads = "Threads"
    case bluesky = "Bluesky", truthSocial = "Truth Social", gab = "Gab", parler = "Parler"
    case mewe = "MeWe", gettr = "Gettr", minds = "Minds", locals = "Locals", vero = "Vero"
    case ello = "Ello", diaspora = "Diaspora", pixelfed = "Pixelfed", lemmy = "Lemmy", nostr = "Nostr"
    case cara = "Cara"

    // MARK: Regional
    case weibo = "Weibo", wechat = "WeChat", qq = "QQ", xiaohongshu = "Xiaohongshu"
    case bilibili = "Bilibili", youku = "Youku", niconico = "Niconico", kakaotalk = "KakaoTalk"
    case line = "Line", viber = "Viber", zalo = "Zalo", vk = "VK", naver = "Naver", daum = "Daum"

    // MARK: Messaging
    case whatsapp = "WhatsApp", telegram = "Telegram", discord = "Discord", slack = "Slack"
    case signal = "Signal", messenger = "Messenger", element = "Element", matrix = "Matrix"
    case threema = "Threema", wire = "Wire", session = "Session", keybase = "Keybase"
    case facetime = "FaceTime", googleChat = "Google Chat"

    // MARK: Live
    case twitchLive = "Twitch Live", facebookGaming = "Facebook Gaming", youtubeGaming = "YouTube Gaming"
    case dlive = "DLive", caffeine = "Caffeine", trovo = "Trovo", picarto = "Picarto", younow = "YouNow"
    case bigoLive = "Bigo Live", streamyard = "StreamYard", streamlabs = "Streamlabs"
    case restream = "Restream", obsLive = "OBS.Live"

    // MARK: Developer
    case github = "GitHub", gitlab = "GitLab", bitbucket = "Bitbucket", stackoverflow = "Stack Overflow"
    case codepen = "CodePen", codesandbox = "CodeSandbox", replit = "Replit", figma = "Figma"
    case dribbble = "Dribbble", behance = "Behance", angellist = "AngelList", producthunt = "Product Hunt"
    case polywork = "Polywork", wellfound = "Wellfound", glitch = "Glitch", kaggle = "Kaggle"
    case vercel = "Vercel", netlify = "Netlify", huggingface = "Hugging Face"
    case swiftPackageIndex = "Swift Package Index", npm = "npm", pypi = "PyPI", cratesIo = "crates.io"
    case dockerHub = "Docker Hub", sourcehut = "SourceHut", codeberg = "Codeberg", linear = "Linear"
    case loom = "Loom", jsfiddle = "JSFiddle", leetcode = "LeetCode", appleDeveloper = "Apple Developer"

    // MARK: AI
    case chatgpt = "ChatGPT", openai = "OpenAI", claude = "Claude", gemini = "Gemini"
    case perplexity = "Perplexity", copilot = "Microsoft Copilot"

    // MARK: Apps
    case appStore = "App Store", googlePlay = "Google Play", testFlight = "TestFlight"

    // MARK: E-commerce
    case amazon = "Amazon", ebay = "eBay", etsy = "Etsy", shopify = "Shopify", alibaba = "Alibaba"
    case aliexpress = "AliExpress", mercari = "Mercari", poshmark = "Poshmark", depop = "Depop"
    case walmart = "Walmart", target = "Target", bestbuy = "Best Buy", wish = "Wish", shein = "SHEIN"
    case wayfair = "Wayfair", temu = "Temu", vinted = "Vinted", zalando = "Zalando", asos = "ASOS"
    case ikea = "IKEA", nike = "Nike", stockx = "StockX", allegro = "Allegro", rakuten = "Rakuten"
    case flipkart = "Flipkart", jd = "JD.com", taobao = "Taobao", tmall = "Tmall", shopee = "Shopee"
    case lazada = "Lazada", mercadoLibre = "Mercado Libre"

    // MARK: Gaming
    case steam = "Steam", epicGames = "Epic Games", battlenet = "Battle.net", origin = "Origin"
    case uplay = "Uplay", gog = "GOG", itchIo = "itch.io", roblox = "Roblox", minecraft = "Minecraft"
    case fortnite = "Fortnite", leagueOfLegends = "League of Legends", valorant = "Valorant"
    case xbox = "Xbox", playstation = "PlayStation", nintendo = "Nintendo"

    // MARK: Financial
    case paypal = "PayPal", venmo = "Venmo", cashapp = "Cash App", zelle = "Zelle", stripe = "Stripe"
    case square = "Square", alipay = "Alipay", paytm = "Paytm", klarna = "Klarna", afterpay = "Afterpay"
    case affirm = "Affirm", chime = "Chime", revolut = "Revolut", wise = "Wise", robinhood = "Robinhood"
    case etoro = "eToro", webull = "Webull", coinbase = "Coinbase", binance = "Binance", kraken = "Kraken"
    case metamask = "MetaMask", cryptoDotCom = "Crypto.com", coingecko = "CoinGecko"
    case coinmarketcap = "CoinMarketCap", polymarket = "Polymarket", kalshi = "Kalshi"
    case tradingview = "TradingView", yahooFinance = "Yahoo Finance"

    // MARK: Crowdfunding
    case kickstarter = "Kickstarter", indiegogo = "Indiegogo", gofundme = "GoFundMe", justgiving = "JustGiving"

    // MARK: Dating
    case tinder = "Tinder", bumble = "Bumble", hinge = "Hinge", match = "Match", okcupid = "OkCupid"
    case plentyoffish = "PlentyOfFish", eharmony = "eHarmony", coffeeMeetsBagel = "Coffee Meets Bagel"
    case happn = "Happn", badoo = "Badoo", grindr = "Grindr", her = "Her", feeld = "Feeld"

    // MARK: Cloud
    case dropbox = "Dropbox", googleDrive = "Google Drive", onedrive = "OneDrive", box = "Box"
    case icloud = "iCloud", mega = "Mega", pcloud = "pCloud", sync = "Sync", mediafire = "MediaFire"
    case wetransfer = "WeTransfer", googlePhotos = "Google Photos"

    // MARK: Publishing & news
    case medium = "Medium", substack = "Substack", wordpress = "WordPress", blogger = "Blogger"
    case ghost = "Ghost", mirror = "Mirror", revue = "Revue", convertkit = "ConvertKit", beehiiv = "Beehiiv"
    case hashnode = "Hashnode", devto = "Dev.to", hackerNews = "Hacker News"
    case nytimes = "The New York Times", theGuardian = "The Guardian", bbc = "BBC", cnn = "CNN"
    case reuters = "Reuters", apNews = "AP News", washingtonPost = "The Washington Post"
    case wsj = "The Wall Street Journal", bloomberg = "Bloomberg", ft = "Financial Times"
    case theEconomist = "The Economist", theVerge = "The Verge", techcrunch = "TechCrunch", wired = "WIRED"

    // MARK: Learning
    case udemy = "Udemy", coursera = "Coursera", edx = "edX", skillshare = "Skillshare"
    case teachable = "Teachable", thinkific = "Thinkific", kajabi = "Kajabi"
    case linkedinLearning = "LinkedIn Learning", khanAcademy = "Khan Academy", udacity = "Udacity"
    case pluralsight = "Pluralsight", masterclass = "MasterClass", brilliantorg = "Brilliant.org"
    case duolingo = "Duolingo"

    // MARK: Web3
    case opensea = "OpenSea", rarible = "Rarible", foundation = "Foundation", superrare = "SuperRare"
    case zora = "Zora", lensProtocol = "Lens Protocol", farcaster = "Farcaster"
    case decentraland = "Decentraland", cryptoVoxels = "Voxels", sandbox = "The Sandbox"
    case axieInfinity = "Axie Infinity", etherscan = "Etherscan"

    // MARK: Conferencing
    case zoom = "Zoom", teams = "Microsoft Teams", googleMeet = "Google Meet", skype = "Skype"
    case webex = "Webex", whereby = "Whereby", jitsi = "Jitsi", gotomeeting = "GoToMeeting"
    case bluejeans = "BlueJeans"

    // MARK: Maps
    case googleMaps = "Google Maps", appleMaps = "Apple Maps", waze = "Waze"
    case openstreetmap = "OpenStreetMap", mapbox = "Mapbox", hereWeGo = "HERE WeGo"
    case citymapper = "Citymapper", what3words = "what3words"

    // MARK: Food
    case ubereats = "Uber Eats", doordash = "DoorDash", grubhub = "Grubhub", postmates = "Postmates"
    case instacart = "Instacart", deliveroo = "Deliveroo", justeat = "Just Eat", seamless = "Seamless"

    // MARK: Travel
    case airbnb = "Airbnb", booking = "Booking.com", expedia = "Expedia", tripadvisor = "TripAdvisor"
    case kayak = "Kayak", hotels = "Hotels.com", vrbo = "VRBO", agoda = "Agoda", uber = "Uber"
    case lyft = "Lyft", bolt = "Bolt", skyscanner = "Skyscanner", trainline = "Trainline", ryanair = "Ryanair"

    // MARK: Events
    case eventbrite = "Eventbrite", meetup = "Meetup", ticketmaster = "Ticketmaster", dice = "DICE"
    case residentAdvisor = "Resident Advisor", bandsintown = "Bandsintown", songkick = "Songkick"
    case setlistFm = "setlist.fm", luma = "Luma"

    // MARK: Productivity
    case notion = "Notion", airtable = "Airtable", trello = "Trello", miro = "Miro", canva = "Canva"
    case linktree = "Linktree", carrd = "Carrd", asana = "Asana", monday = "Monday.com", clickup = "ClickUp"
    case jira = "Jira", calendly = "Calendly", calCom = "Cal.com", typeform = "Typeform", tally = "Tally"
    case zapier = "Zapier", evernote = "Evernote", todoist = "Todoist", onePassword = "1Password"
    case bitwarden = "Bitwarden", obsidian = "Obsidian", craft = "Craft", gmail = "Gmail"
    case googleCalendar = "Google Calendar", googleForms = "Google Forms"

    // MARK: Reference
    case wikipedia = "Wikipedia", wikidata = "Wikidata", wiktionary = "Wiktionary"
    case wikimedia = "Wikimedia Commons", arxiv = "arXiv", pubmed = "PubMed", doi = "DOI"
    case semanticScholar = "Semantic Scholar", researchGate = "ResearchGate", openAlex = "OpenAlex"
    case internetArchive = "Internet Archive", googleScholar = "Google Scholar", googleSearch = "Google Search"

    // MARK: Entertainment
    case netflix = "Netflix", primeVideo = "Prime Video", disneyPlus = "Disney+", max = "Max"
    case hulu = "Hulu", crunchyroll = "Crunchyroll", plex = "Plex", paramountPlus = "Paramount+"
    case peacock = "Peacock", appleTV = "Apple TV", appleBooks = "Apple Books", imdb = "IMDb"
    case letterboxd = "Letterboxd", tmdb = "TMDB", rottenTomatoes = "Rotten Tomatoes"
    case goodreads = "Goodreads", kindle = "Kindle"

    // MARK: Fitness
    case strava = "Strava", garmin = "Garmin Connect", komoot = "Komoot", allTrails = "AllTrails"
    case myFitnessPal = "MyFitnessPal", peloton = "Peloton"

    // MARK: Images
    case imgur = "Imgur", giphy = "Giphy", flickr = "Flickr", unsplash = "Unsplash", pexels = "Pexels"
    case pixabay = "Pixabay", deviantart = "DeviantArt", artstation = "ArtStation", pixiv = "Pixiv"
    case tenor = "Tenor"

    // MARK: Subscription
    case onlyfans = "OnlyFans", patreon = "Patreon", fansly = "Fansly", kofi = "Ko-fi"
    case buymeacoffee = "Buy Me a Coffee", gumroad = "Gumroad", subscribestar = "SubscribeStar"

    case unknown = "Unknown"

    // MARK: - Derived

    /// The family this platform belongs to.
    public var category: PlatformCategory { PlatformDomains.categories[self] ?? .unknown }

    /// Whether the service has shut down. Old links still exist and are still
    /// worth identifying — "this is a Google Podcasts link, which no longer works".
    public var isDefunct: Bool { PlatformDomains.retired[self] != nil }

    /// The year the service closed, when it has.
    public var retiredIn: Int? { PlatformDomains.retired[self]?.year }

    /// What replaced it, when something did.
    public var successor: Platform? { PlatformDomains.retired[self]?.successor }
}
