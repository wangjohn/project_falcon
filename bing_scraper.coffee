casper = require("casper").create(
  verbose: true
  logLevel: "debug"
  waitTimeout: 10000
)

scrape = (casper) ->
  casper.start()
  casper.thenOpen("http://www.bing.com/flights/search?q=flights+from+o%27hare+international+airport+%28ord%29+-+chicago+to+all+airports+%28was%29+-+washington&oform=&form=FDTPSF&b=COACH&p=1&vo1=O%27Hare+International+Airport+%28ORD%29+-+Chicago%2C+IL&o1=ORD&dm1=06%2F27%2F2014&ve1=All+airports+%28WAS%29+-+Washington%2C+DC&e1=WAS")

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
    @echo JSON.stringify(flightResults)

  casper.run()

scrape(casper)
