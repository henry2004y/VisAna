pro extract_galileo_times, $
                           firstpict=firstpict, lastpict=lastpict, dpict=dpict, $
                           stretch = stretch, $
                           brange = brange, $
                           timeshift0=timeshift0, timeshift1=timeshift1, $
                           animate=animate, savemovie=savemovie, $
                           xextract=xextract, yextract=yextract, zextract=zextract, $
                           ivarextract0=ivarextract0, ivarextract1=ivarextract1, $
                           varextract=varextract, nameextract=nameextract, $
                           freqrange=freqrange

  common file_head
  common plot_data
  common log_data
  common getpict_param
  common getlog_param
  common plotlog_param

  nfile=0
  if n_elements(filename) eq 0 then begin
     filename = ''
     askstr,'filename(s)   ',filename
  endif

  string_to_array,filename,filenames,nfile,/wildcard

  print, 'filenames=',filenames
  if nfile eq 0 then begin
     print,'Could not match filename=', filename
     retall
  endif

  if nfile gt 3 then begin
     print,'At most 3 files can be compared, nfile=', nfile
     retall
  endif

  if n_elements(xrange) ne 2 then xrange = [945, 967]

  ; defaults for FFT
  if n_elements(freqrange) gt 0 then begin
     if n_elements(smooths) eq 0 then smooths = intarr(nfile+1)+5
     if n_elements(brange) eq 0 then brange = [3e-6,20.0]
  endif

  print,'nfile=',nfile

  ; selection of snapshots
  if n_elements(firstpict) eq 0 then firstpict = 1
  if n_elements(lastpict)  eq 0 then lastpict  = 1000
  if n_elements(dpict)     eq 0 then dpict     = 1

  ; stretching satellite trajectory
  if n_elements(stretch) eq 0 then stretch = 1.0

  if n_elements(brange) eq 0 then brange = [-200.0, 200.0]
  
  if n_elements(colors) lt nfile+1 then $
     colors = [255,100,250,150]

  ; animation
  if not keyword_set(animate) then animate = 0
  
  ; saving movie
  if not keyword_set(savemovie) then savemovie = 0

  ; extract values at xextract, yextract, zextract into an array
  doextract = n_elements(xextract) gt 0
  if doextract and n_elements(yextract) eq 0 then yextract=0.0
  if doextract and n_elements(zextract) eq 0 then zextract=0.0

  get_log, 'Galileo_G1_flyby_MAG.dat', datasat0, varnamesat0, timesat0, 's', verbose='sat'

  ; generate a 1 second time series within xrange
  timemin  = long(xrange[0]*60.0)
  timemax  = long(xrange[1]*60.0)
  ntimesat = timemax-timemin+1
  timesat  = timemin + lindgen(ntimesat)

  ; Create interpolated satallite data
  varnamesat = ['time', 'x', 'y', 'z', 'bx', 'by', 'bz']
  datasat = fltarr(ntimesat,7)

  datasat(*,0) = timesat
  for ivar = 1, 6 do $
     datasat(*,ivar) = interpol(datasat0(*,ivar+5), timesat0, timesat)

  ; Get stretched satellite trajectrory
  xSat   = datasat(*,1) * stretch
  ySat   = datasat(*,2) * stretch
  zSat   = datasat(*,3) * stretch

  ; open and read first snapshot from all the 3D IDL files
  get_file_types

  ; limit lastpict
  lastpict = lastpict < min(npictinfiles)

  for ifile = 0, nfile - 1 do begin
     filename = filenames(ifile)
     filetype = filetypes(ifile)
     open_file, 10, filename, filetype
     get_pict, 10, filename, filetype, 1, error
     close, 10

     if ndim ne 3 then begin
        print, 'Error in ',filename,': ndim=', ndim,' is not 3
        retall
     endif

     if variables(7) ne 'bx' then begin
        print, 'Error in ',filename,': variables(7)=', variables(7),' is not bx
        retall
     endif
  endfor

  maxpict = (lastpict - firstpict)/dpict + 1

  ; Create arrays for model tiem and mangetic field
  time0      = fltarr(maxpict)
  time1      = fltarr(maxpict)
  time2      = fltarr(maxpict)
  b0 = fltarr(ntimesat,3,maxpict)
  b1 = fltarr(ntimesat,3,maxpict)
  b2 = fltarr(ntimesat,3,maxpict)

  if doextract then begin
     if n_elements(ivarextract0) eq 0 then begin
        ivarextract0 = 0
        ivarextract1 = nw-1
     endif else $
        if n_elements(ivarextract1) eq 0 then $
           ivarextract1 = ivarextract0

     varextract = fltarr(maxpict,ivarextract1-ivarextract0+2,nfile)

     nameextract = ['time', variables(3+ivarextract0:3+ivarextract1)]
     print,'extracting variables:', nameextract

  endif

  ; Since each snapshot is separated by 1 second the time range is simply
  timerange = lastpict - firstpict + 1

  print, 'maxpict = ', maxpict, ' timerange=', timerange

  ; Extract magnetic field along the trajectory from each file
  for ifile = 0, nfile - 1 do begin
     open_file, 10, filenames(ifile), filetypes(ifile)

     nextpict = firstpict

     for npict = 0, maxpict-1 do begin

        get_pict,10, filenames(ifile), filetypes(ifile), nextpict, error

        print,'npict, nextpict, time=', npict, nextpict, time

        ; Get the grid limits and grid resolution
        xmin = min(x(*,0,0,0))
        ymin = min(x(0,*,0,1))
        zmin = min(x(0,0,*,2))
        xmax = max(x(*,0,0,0))
        ymax = max(x(0,*,0,1))
        zmax = max(x(0,0,*,2))
        dx = (xmax - xmin)/(nx(0) - 1)
        dy = (ymax - ymin)/(nx(1) - 1)
        dz = (zmax - zmin)/(nx(2) - 1)

        if doextract then begin
           iextract = (xextract - xmin)/dx > 0 < (nx(0)-1)
           jextract = (yextract - ymin)/dy > 0 < (nx(1)-1)
           kextract = (zextract - zmin)/dz > 0 < (nx(2)-1)

           varextract(npict,0,ifile) = time
           for ivar = ivarextract0, ivarextract1 do $
              varextract(npict,ivar-ivarextract0+1,ifile) = $
              interpolate(w(*,*,*,ivar),iextract,jextract,kextract)
        endif

        ; normalized satellite location of selected points
        isat = (xSat - xmin)/dx
        jsat = (ySat - ymin)/dy
        ksat = (zSat - zmin)/dz

        ; interpolate into the synthetic satellite files
        case ifile of
           0: begin
              time0(npict) = time
              b0(*,0,npict) = interpolate(w(*,*,*,4), isat, jsat, ksat)
              b0(*,1,npict) = interpolate(w(*,*,*,5), isat, jsat, ksat)
              b0(*,2,npict) = interpolate(w(*,*,*,6), isat, jsat, ksat)
           end
           1: begin
              time1(npict) = time
              b1(*,0,npict) = interpolate(w(*,*,*,4), isat, jsat, ksat)
              b1(*,1,npict) = interpolate(w(*,*,*,5), isat, jsat, ksat)
              b1(*,2,npict) = interpolate(w(*,*,*,6), isat, jsat, ksat)
           end
           2: begin
              time2(npict) = time
              b2(*,0,npict) = interpolate(w(*,*,*,4), isat, jsat, ksat)
              b2(*,1,npict) = interpolate(w(*,*,*,5), isat, jsat, ksat)
              b2(*,2,npict) = interpolate(w(*,*,*,6), isat, jsat, ksat)
           end
        endcase

        nextpict = dpict
     endfor
     close, 10
  endfor

  if !d.name eq 'X' then begin
    if !d.window lt 0 then window
    wshow
  endif


  ; Synthetic satellite data
  datamodel0 = datasat
  datamodel1 = datasat
  datamodel2 = datasat

  if n_elements(timeshift0) eq 0 then timeshift0 = 0 $
  else if n_elements(timeshift1) eq 0 then timeshift1 = timeshift0
  if n_elements(timeshift1) eq 0 then timeshift1 = timerange - 1

  multishift = (timeshift1 - timeshift0) gt 1 

  if multishift and not savemovie then animate = 1

  if animate then xinteranimate,set=[!d.x_size,!d.y_size,timerange]
  if savemovie then spawn,'/bin/mkdir -p Movie'

  meandb0 = 0.
  meandb1 = 0.
  meandb2 = 0.
  mindb0  = 1000.0
  mindb1  = 1000.0
  mindb2  = 1000.0

  title = ' '

  for timeshift = timeshift0, timeshift1 do begin

     if multishift then title = 'timeshift=' + string(timeshift)

     ; starting values for storing jump locations
     jpictlast = -1000
     jumps = [-1000.0]

     for itime = 0, ntimesat-1 do begin
        time = (timesat(itime) - timeshift) mod timerange
        ipict = fix(time+0.5)

        if ipict eq 0 then $
           jumps = [jumps,timesat(itime)/60.0]

        datamodel0(itime,4:6)    = b0(itime,*,ipict)
        if nfile gt 1 then $
           datamodel1(itime,4:6) = b1(itime,*,ipict)
        if nfile gt 2 then $
           datamodel2(itime,4:6) = b2(itime,*,ipict)
     endfor

     logfilenames=['Galileo', filenames]
     logfunc='bx by bz'
     wlognames =varnamesat
     wlognames1=varnamesat
     wlognames2=varnamesat
     wlognames3=varnamesat
     wlog =datasat
     wlog1=datamodel0
     wlog2=datamodel1
     wlog3=datamodel2
     yranges = [[brange], [brange], [brange]]
     if n_elements(freqrange) gt 0 then begin
        xrange=freqrange
        dofft=1
        timeunit='s'
        xtitle = 'Frequency [Hz]'
        ytitles = ['FFT Bx [nT!U2!N]', 'FFT By [nT!U2!N]', 'FFT Bz [nT!U2!N]']
     endif else begin
        timeunit='m'
        xtitle='time [m]'
        ytitles = ['Bx [nT]', 'By [nT]', 'Bz [nT]']
     endelse
     plot_log

     ; Mark the beginning of cycles
     if lastpict gt firstpict then oplot,jumps,0*jumps,psym=1,symsize=3

     dbx = total(abs(datasat(*,4)-datamodel0(*,4)))/ntimesat
     dby = total(abs(datasat(*,5)-datamodel0(*,5)))/ntimesat
     dbz = total(abs(datasat(*,6)-datamodel0(*,6)))/ntimesat
     db  = (dbx+dby+dbz)/3.
     meandb0 = meandb0 + db
     mindb0  = mindb0 < db
     if multishift then $
        xyouts,/norm,0.8,0.95,'dBx,dBy,dBz,dB='+ string(dbx,dby,dbz,db,format='(4f5.0)'), $
            color=colors(1)

     if nfile gt 1 then begin
        dbx = total(abs(datasat(*,4)-datamodel1(*,4)))/ntimesat
        dby = total(abs(datasat(*,5)-datamodel1(*,5)))/ntimesat
        dbz = total(abs(datasat(*,6)-datamodel1(*,6)))/ntimesat
        db  = (dbx+dby+dbz)/3.
        meandb1 = meandb1 + db
        mindb1  = mindb1 < db
        if multishift then $
           xyouts,/norm,0.8,0.94,'dBx,dBy,dBz,dB='+ string(dbx,dby,dbz,db,format='(4f5.0)'), $
                  color=colors(2)
     endif

     if nfile gt 2 then begin
        dbx = total(abs(datasat(*,4)-datamodel2(*,4)))/ntimesat
        dby = total(abs(datasat(*,5)-datamodel2(*,5)))/ntimesat
        dbz = total(abs(datasat(*,6)-datamodel2(*,6)))/ntimesat
        db  = (dbx+dby+dbz)/3.
        meandb2 = meandb2 + db
        mindb2  = mindb2 < db
        if multishift then $
           xyouts,/norm,0.8,0.93,'dBx,dBy,dBz,dB='+ string(dbx,dby,dbz,db,format='(4f5.0)'), $
                  color=colors(3)
     endif

     if animate then xinteranimate,frame=timeshift,window=!d.window
     if savemovie then write_image, $
        string(FORMAT='("Movie/",i4.4,".png")',npict), 'png', $
        tvrd(true=1)

  endfor

  meandb0 = meandb0/timerange
  meandb1 = meandb1/timerange
  meandb2 = meandb2/timerange

  print,                   'min(dB), mean(dB)=', mindb0, meandb0,' for ',filenames(0)
  if nfile gt 1 then print,'min(dB), mean(dB)=', mindb1, meandb1,' for ',filenames(1)
  if nfile gt 2 then print,'min(dB), mean(dB)=', mindb2, meandb2,' for ',filenames(2)

  if animate then xinteranimate,5,/keep_pixmaps

end
