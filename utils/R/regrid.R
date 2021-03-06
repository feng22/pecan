##' Regrid dataset to even grid
##' 
##' @title regrid
##' @param latlon.data dataframe with lat, lon, and some value to be regridded
##' @return dataframe with regridded data
##' @author David LeBauer
regrid <- function(latlon.data) {
  library(raster)
  library(sp)
  ## from http://stackoverflow.com/a/15351169/513006
  spdf <- SpatialPointsDataFrame(data.frame(x = latlon.data$lon, y = latlon.data$lat), 
                                 data = data.frame(z = latlon.data$yield))
  ## Make evenly spaced raster, same extent as original data
  e <- extent(spdf)
  ## Determine ratio between x and y dimensions
  ratio <- (e@xmax - e@xmin) / (e@ymax - e@ymin)
  
  ## Create template raster to sample to
  r  <- raster(nrows = 56, ncols = floor(56 * ratio), ext = extent(spdf))
  rf <- rasterize(spdf, r, field = "z", fun = mean)
  
  # rdf <- data.frame( rasterToPoints( rf ) ) colnames(rdf) <-
  # colnames(latlon.data)
  arf <- as.array(rf)
  
  # return(rdf)
  return(arf)
} # regrid


##' Write gridded data to netcdf file
##'
##' @title grid2netcdf
##' @param grid.data 
##' @return writes netCDF file
##' @author David LeBauer
grid2netcdf <- function(gdata, date = "9999-09-09", outfile = "out.nc") {
  
  ## Fill in NA's
  lats      <- unique(gdata$lat)
  lons      <- unique(gdata$lon)
  dates     <- unique(gdata$date)
  latlons   <- data.table(expand.grid(lat = lats, lon = lons, date = dates))
  grid.data <- merge(latlons, gdata, by = c("lat", "lon", "date"), all.x = TRUE)
  lat       <- ncdf4::ncdim_def("lat", "degrees_east", vals = lats, longname = "station_latitude")
  lon       <- ncdf4::ncdim_def("lon", "degrees_north", vals = lons, longname = "station_longitude")
  time      <- ncdf4::ncdim_def(name = "time", units = paste0("days since 1700-01-01"), 
                         vals = as.numeric(ymd(paste0(years, "01-01")) - ymd("1700-01-01")), 
                         calendar = "standard", 
                         unlim = TRUE)
  
  yieldvar <- mstmipvar("CropYield", lat, lon, time)
  nc <- ncdf4::nc_create(filename = outfile, vars = list(CropYield = yieldvar))
  
  ## Output netCDF data
  #    ncvar_put(nc, varid = yieldvar, vals = grid.data[order(lat, lon, order(ymd(date )))]$yield)
  #    ncvar_put(nc, varid = yieldvar, vals = grid.data[order(order(ymd(date), lat, lon))]$yield)
  ncdf4::ncvar_put(nc, varid = yieldvar, vals = yieldarray)
  
  ncdf4::ncatt_put(nc, 0, "description", "put description here")
  ncdf4::nc_close(nc)
} # grid2netcdf
