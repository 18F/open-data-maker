

def address_data
  @address_data ||= StringIO.new <<-eos
name,address,city
Paul,15 Penny Lane,Liverpool
Michelle,600 Pennsylvania Avenue,Washington
Marilyn,1313 Mockingbird Lane,Burbank
Sherlock,221B Baker Street,London
Clark,66 Lois Lane,Smallville
Bart,742 Evergreen Terrace,Springfield
Paul,19 N Square,Boston
Peter,66 Parker Lane,New York
eos
  @address_data.rewind
  @address_data
end

def geo_data
  @geo_data ||= StringIO.new <<-eos
state,city,lat,lon
CA,San Francisco,37.727239,-123.032229
NY,"New York",40.664274,-73.938500
CA,"Los Angeles",34.019394,-118.410825
IL,Chicago,41.837551,-87.681844
TX,Houston,29.780472,-95.386342
PA,Philadelphia,40.009376,-75.133346
CA,"San Jose",37.296867,-121.819306
MA,Boston,42.331960,-71.020173
WA,Seattle,47.620499,-122.350876
eos
  @geo_data.rewind
  @geo_data
end
