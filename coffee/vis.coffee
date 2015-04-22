
root = exports ? this

names = ["jeffrey_heer", "laurmccarthy", "vlandham", "ramik", "lenagroeger","philogb","iwebst", "nigelblue", "jonobr1", "awoodruff", "eagereyes", "moebio", "hfairfield", "ilyabo", "alykat", "laneharrison", "dominikus", "fisherdanyel", "adamperer", "vlh","cambecc", "arnicas", "boaz", "#openvisconf"]

titles = ["Jeffrey Heer", "Lauren McCarthy", "Jim V", "Ramik Sadana", "Lena Groeger", "Nicolas G Belmonte", "Ian Webster", "Nigel Holmes", "Jono Brandel", "Andy Woodruff", "Robert Kosara"]

starts = {
  "jeffrey_heer":{diff:9 , day:"6"},
  "laurmccarthy":{diff:10, day:"6"}
  "vlandham":{diff:11, day:"6"}
  "ramik":{hour:"11:30am", diff:11.5 , day:"6"}
  "lenagroeger":{diff:12, day:"6"}
  "philogb":{hour:"1:30pm", diff:13.5 , day:"6"}
  "iwebst":{diff:14 , day:"6"}
  "nigelblue":{diff:15 , day:"6"}
  "jonobr1":{diff:16 , day:"6"}
  "awoodruff":{diff:17 , day:"6"}
  "eagereyes":{hour:"5:30pm", diff:17.5 , day:"6"}
  "moebio":{diff:9 , day:"7"}
  "hfairfield":{diff:10 , day:"7"}
  "ilyabo":{diff:11 , day:"7"}
  "alykat":{hour:"11:30am", diff:11.5 , day:"7"}
  "laneharrison":{diff:12 , day:"7"}
  "dominikus":{hour:"1:30pm", diff:13.5 , day:"7"}
  "fisherdanyel":{diff:14 , day:"7"}
  "adamperer":{diff:15 , day:"7"}
  "vlh":{diff:16 , day:"7"}
  "cambecc":{diff:17 , day:"7"}
}

timeString = (hour) ->
  hr = ""
  if hour > 12
    hr = (hour - 12) + "pm"
  else if hour == 12
    hr = "12pm"
  else
    hr = hour + "am"
  hr


url = /http:\/\/.*(\s|$)/
removeUrls = (string) ->
  string.replace(url,"")

findRetweets = (data) ->
  uniqs = d3.map()
  regex = /^RT @\w*:\s+/

  missing = 0

  data.forEach (d) ->
    orgText = removeUrls(d["Text"])
    if d.rt
      orgText = orgText.replace(regex, "")
      if uniqs.has(orgText)
        uniqs.set(orgText, uniqs.get(orgText) + 1)
      else
        missing += 1
    else
      uniqs.set(orgText, 0)
      # uniqs[d["Text"]] = 0
  data.forEach (d) ->
    orgText = removeUrls(d["Text"])
    if d.rt
      d.retweets = 0
    else
      # d.retweets = uniqs[d["Text"]]
      d.retweets = uniqs.get(orgText)



setupData = (data) ->
  parser = d3.time.format.utc("%Y-%m-%d %H:%M:%S %Z")
  data = data.reverse()
  data.forEach (d) ->
    d.show = true
    d.date = parser.parse(d["Posted at"])
    # d.date = moment.utc(d["Posted at"], "YYYY-MM-DD HH:mm:ss Z")
    d.time = d.date.getTime()
    d.rt = d["Text"].startsWith("RT")
    d.day = d.date.getDate()
    # d.day = d.date.date()


  findRetweets(data)

  # data = data.filter (d) ->
  #   d.v

  # data = data.filter (d) ->
  #   d.date > startDate

  nest = d3.nest()
    .key ((d) -> d.day)
    .sortKeys(d3.ascending)
    # .sortValues((d) -> d.time)
    .entries(data)

  nest.forEach (n) ->
    startDate = new Date()
    startDate.setTime(n.values[0].time)
    startDate.setHours(0)
    startDate.setMinutes(0)
    startDate.setSeconds(0)

    # startDate = moment(n.values[0].date)
    # startDate.hours(0)
    # startDate.minutes(0)
    # startDate.seconds(0)

    n.values.forEach (d) ->
      d.diffDate = d.date - startDate
    n.diffDateExtent = d3.extent(n.values, (d) -> d.diffDate)

  # nest = nest.filter (d) ->
  #   d.key == "6" || d.key == "7"
  nest

Plot = () ->
  width = 140
  height = 400
  tooltip = CustomTooltip("tooltip", 240)
  allData = []
  data = []
  points = null
  days = null
  margin = {top: 20, right: 50, bottom: 30, left: 40}
  timeScale = d3.scale.linear().domain([0,10]).range([0,height])
  dayScale = d3.scale.ordinal().rangePoints([0,width], 1.0)
  rScale = d3.scale.sqrt().range([5, 40])
  startSecs = 60 * 60 * 6 * 500
  secsInDay = (1000 * 60 * 60 * 24) # - (startSecs)
  # startSecs = 0
  # dayScale = d3.scale.linear().domain([0,10]).range([0,height])
  yValue = (d) -> parseFloat(d.y)
  # color = d3.scale.category10()
  color = d3.scale.ordinal().domain([false, true]).range(["rgb(58,177,139)", "rgb(183,138,67)"])

  g = null

  filterDay = (startData) ->
    startData.filter (n) ->
      n.key == "6" || n.key == "7" || n.key == "8"

  # filterUser = (user) ->
  #   console.log(user)
  #   data = allData.forEach (n) ->
  #     n.values.forEach (d) ->
  #       d.show = d["Screen name"].toLowerCase().includes(user) || d["Text"].toLowerCase().includes(user)
  #   console.log(data)
  #   data
  filterUser = (startData, user) ->
    mdata = _.cloneDeep(startData)
    mdata.forEach (n) ->
      n.values = n.values.filter (d) ->
        d["Screen name"].toLowerCase().includes(user) || d["Text"].toLowerCase().includes(user)
      n
    mdata


  chart = (selection) ->
    selection.each (rawData) ->

      allData = setupData(rawData)
      data = allData

      timeScale.domain([startSecs, secsInDay])
      # dayScale.domain(data.map (d) -> d.key)
      dayScale.domain(["6","7", "8"])
      tweetExtent = d3.extent(data, (n) -> d3.max(n.values, (d) -> d.retweets))
      rScale.domain(tweetExtent)

      svg = d3.select(this).selectAll("svg").data(names)
      gEnter = svg.enter().append("svg").append("g")

      svg.attr("width", width + margin.left + margin.right )
      svg.attr("height", height + margin.top + margin.bottom )

      g = svg.select("g")
        .attr("transform", "translate(#{margin.left},#{margin.top})")


      update()

  mouseover = (d,i) ->
    html = "#{d["Screen name"]}: <br/>#{d["Text"]}"
    console.log(d)
    tooltip.showTooltip(html,d3.event)

  mouseout = (d,i) ->
    tooltip.hideTooltip()

  mouseclick = (d,i) ->
    url = "https://twitter.com/x/status/#{d["ID"]}"
    window.open(url, "_blank")


  update = () ->
    # points = g.append("g").attr("id", "vis_points")
    # nameG = points.selectAll(".name")
    #   .data(names).enter()
    #   .append("g")
    #   .attr("class", "name")
    #   .attr("transform", (n,i) -> "translate(#{width * i},0)")
    days = g.selectAll(".day")
      .data((n) -> filterUser(filterDay(allData), n)).enter()
      .append("g")
      .attr("class", "day")
      .attr("transform", (n) -> "translate(#{dayScale(n.key)},0)")

    points = days.selectAll(".point")
      .data(((n) -> n.values.filter((d) -> d.show)), ((d) -> d["ID"]))
    points.enter()
      .append("circle")
      .attr("cy", (d) -> timeScale(d.diffDate))
      .attr("r",  4)
      .attr("class", "point")
      .attr("fill", (d) -> color(d.rt))
      .attr("opacity", (d) -> if d.rt then 0.3 else 0.8)
      .on("mouseover", mouseover)
      .on("mouseout", mouseout)
      .on("click", mouseclick)

    points.exit().remove()

    halos = days.selectAll(".halo")
      .data(((n) -> n.values.filter((d) -> d.show && !d.rt)), ((d) -> d["ID"]))
    halos.enter()
      .append("circle")
      .attr("cy", (d) -> timeScale(d.diffDate))
      # .attr("cy", (d) -> dayScale(yValue(d)))
      # .attr("cy", (d) -> height / 3)
      # .attr("r", 6)
      .attr("r", (d) -> rScale(d.retweets))
      .attr("class", "halo")
      .attr("fill", (d) -> color(d.rt))
      .attr("opacity", (d) -> if d.rt then 0.3 else 0.3)
      .on("mouseover", mouseover)
      .on("mouseout", mouseout)
      .on("click", mouseclick)

    points = days.selectAll(".point")
      .data(((n) -> n.values.filter((d) -> d.show)), ((d) -> d["ID"]))

    g.append("text")
      .text((n) -> n)
      .attr("x", width / 2)
      .attr("y", 10)
      .attr("text-anchor", "middle")

    daytitles = [{day:"6", title:"day 1"},{day:"7", title:"day 2"}, {day:"8", title:"day after"}]
    g.selectAll(".day-title").data(daytitles)
      .enter()
      .append("text")
      .attr("class", "day-title")
      .attr("text-anchor", "middle")
      .attr("x", (d) -> dayScale(d.day))
      .attr("y", height)
      .attr("dy", (d,i) -> if i == 1 then 20 else 10)
      .text((d) -> d.title)

    timetitles = g.selectAll(".time-title").data((n) -> if starts[n] then [starts[n]] else [])
      .enter()
    timetitles.append("text")
      .attr("class", "time-title")
      .attr("x", (d) -> dayScale(d.day))
      .attr("y", (d) -> timeScale((d.diff * 60 * 60 * 1000) - startSecs))
      .attr("dx", (d) -> if d.day == "6" then -50 else 30)
      .attr("dy", -5)
      .attr("text-anchor", (d) -> if d.day == "6" then "right" else "left")
      .text((d) -> if d.hour then d.hour else timeString(d.diff))

    g.attr("opacity", 1e-6)
    g.transition()
      .duration(600)
      .delay((d,i) -> i * 200)
      .attr("opacity",1.0)

  chart.filter = (user) ->
    filterUser(user)
    update()

  chart.height = (_) ->
    if !arguments.length
      return height
    height = _
    chart

  chart.width = (_) ->
    if !arguments.length
      return width
    width = _
    chart

  chart.margin = (_) ->
    if !arguments.length
      return margin
    margin = _
    chart

  chart.y = (_) ->
    if !arguments.length
      return yValue
    yValue = _
    chart

  return chart

root.Plot = Plot

root.plotData = (selector, data, plot) ->
  d3.select(selector)
    .datum(data)
    .call(plot)


$ ->

  plot = Plot()
  display = (error, data) ->
    plotData("#vis", data, plot)

    d3.select("#search").on "input", (e) ->
      plot.filter(this.value.toLowerCase())


  queue()
    .defer(d3.csv, "data/openvis.csv")
    .await(display)

