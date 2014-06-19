casper = require("casper").create(
  verbose: true
  waitTimeout: 10000
)
fs = require("fs")

BASE_URL = "http://www.bing.com/flights/search?q=flights&ofrom=&form=FDTPSF&b=COACH&p=1&"
BASE_FILENAME = "bing_flight_data"

AIRPORT_PAIRS = [
  ["O'Hare International Airport (ORD) - Chicago, IL", "Dulles International Airport (IAD) - Washington, DC"]
]

constructOneWayUrl = (departureAirport, arrivalAirport, flightDate) ->
  departureCode = retrieveAirportCode(departureAirport)
  arrivalCode = retrieveAirportCode(arrivalAirport)
  encodedDepartureAirport = encodeURIComponent(departureAirport)
  encodedArrivalAirport = encodeURIComponent(arrivalAirport)
  encodedFlightDate = encodeURIComponent(flightDate)

  urlConstructorArray = [
    "vo1=#{encodedDepartureAirport}",
    "o1=#{departureCode}",
    "ve1=#{encodedArrivalAirport}",
    "e1=#{arrivalCode}",
    "dm1=#{encodedFlightDate}"
  ]
  BASE_URL + urlConstructorArray.join("&")

retrieveAirportCode = (airportName) ->
  regexMatchResult = /\(([A-Z]{3})\)/.exec(airportName)
  if regexMatchResult
    regexMatchResult[1]
  else
    throw new Error("Invalid airport name -- cannot retrieve airport code")

scrapeAirportPairs = (casper, airportPairs, flightDate, dataHolder) ->
  for pair in airportPairs
    departureAirport = pair[0]
    arrivalAirport = pair[1]
    url = constructOneWayUrl(departureAirport, arrivalAirport, flightDate)
    console.log url
    completeFlightResults(casper, url, flightDate, dataHolder)

completeFlightResults = (casper, url, flightDate, dataHolder) ->
  casper.thenOpen(url)
  casper.waitForSelector("#results .resultsTable")
  casper.waitWhileVisible("#fltSearchContainer .SearchParamContainer .searching")

  casper.then ->
    flightResults = @evaluate ->
      resultsArray = document.querySelectorAll(".resultsTable .result")
      Array::map.call resultsArray, (e) ->
        airline: e.querySelector(".airline").innerHTML
        from_airport: e.querySelectorAll(".airport .arrowOffset")[0].innerHTML
        to_airport: e.querySelectorAll(".airport .arrowOffset")[1].innerHTML
        leave: e.querySelector(".leave").innerHTML
        arrive: e.querySelector(".arrive").innerHTML
        duration: e.querySelector(".duration").innerHTML
        stops: e.querySelector(".stops").innerHTML
        price: e.querySelector(".price .price").innerHTML
    flightResults["date_retrieved"] = Date.now()
    flightResults["flight_date"] = flightDate
    @echo JSON.stringify(flightResults)

    dataHolder.push.apply(dataHolder, flightResults)

persistScrapeResults = (dataHolder) ->
  casper.then ->
    jsonData = JSON.stringify(dataHolder)
    filename = BASE_FILENAME + "-" + Date.now()
    fs.write(filename, jsonData, "w")

scrape = (casper) ->
  casper.start()
  dataHolder = []
  scrapeAirportPairs(casper, AIRPORT_PAIRS, "07/14/2014", dataHolder)
  persistScrapeResults(dataHolder)
  casper.run()

scrape(casper)
