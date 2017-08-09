       subroutine S28_RupDims (sourceType, rupWidth, aveWidth, rupArea, faultLen,
     1                     faultWidth, nLocYST1, ystep, rupLen)
       
       implicit none
       
c      declarations passed in
       integer sourceType
       real aveWidth, rupArea, faultLen, faultWidth, ystep

c      declarations passed in and out
       real rupWidth

c      declarations passed out
       integer nLocYST1
       real rupLen
       
c           Check that rupture width doesn't exceed fault width and rupture area doesn't
c           exceed fault area. Set rupture length
            if (sourceType .eq. 1 ) then                     
              if (rupWidth .gt. aveWidth ) then
                rupWidth = aveWidth
              endif
              rupLen = rupArea / rupWidth
              if (rupLen .gt. faultLen) then
                rupLen = faultLen
              endif
              nLocYST1 = (aveWidth - rupWidth)/yStep + 1
            elseif (sourceType .eq. 5 .or. sourceType .eq. 6) then
              rupLen = rupArea / rupWidth
              if (rupLen .gt. faultLen) then
                rupLen = faultLen
              endif
            elseif (sourceType .eq. 7) then
              rupWidth = 12.0
            elseif (sourceType .eq. 4 ) then
              if (rupWidth .gt. faultWidth) then                                        
                 rupWidth = faultWidth                                                          
              endif                                                                     
              rupLen = rupArea / rupWidth
              
c           Otherwise source is area  
            else
              if (rupWidth .gt. faultWidth) then                                        
                rupWidth = faultWidth                                                          
              endif                                                                     
              rupLen = rupArea / rupWidth
            endif

        return
       end


c ----------------------------------------------------------------------

      subroutine s28_nLocXcells (sourceType, nLocXAS, grid_n, nfltgrid, fltgrid_w,
     1                     rupWidth, fltgrid_a, ruparea, nLocYST1, nLocX, n1AS, n2AS,
     2                     h_listric, logA_shal, logA_deep, fltgrid_z,
     3                     iDD_shal_min, iDD_shal_max, iDD_deep_min, iDD_deep_max)
     
      implicit none
      include 'pfrisk.h'

c     declarations passed in
      integer sourceType, nLocXAS, grid_n, nfltgrid(2), nLocYST1
      real fltgrid_w(MAXFLT_DD,MAXFLT_AS), rupWidth, fltgrid_a(MAXFLT_DD,MAXFLT_AS),
     1      ruparea
      real h_listric, logA_shal, logA_deep, sumArea_shallow, sumArea_deep
      real fltGrid_z(MAXFLT_DD,MAXFLT_AS)
      integer iDD_shal_min, iDD_shal_max, iDD_deep_min, iDD_deep_max

c     declarations passed out
      integer nLocX, n1AS(MAXFLT_AS), n2AS(MAXFLT_AS)

c     declarations only this subroutine
      integer countnLocX, in2m, in2, iw, in1
      real colarea, colarew

c     Set nLocX for grid and area sources
      if (sourceType .eq. 2 .or. sourceType .eq. 3) then
         nLocX = nLocXAS
      else if (sourceType .eq. 4) then
         nLocX = grid_n
      else if (sourcetype .eq. 7) then
         nLocX = 1

c     Set nLocX, n1AS, and n2AS for fault sources
      else

c       Initialize total area for rupture cells at depths shallower and
c       deeper than the break depth for listric faulting
        sumArea_shallow = 0.
        sumArea_deep = 0.
        iDD_shal_min = 100000
        iDD_shal_max = 0
        iDD_deep_min = 100000
        iDD_deep_max = 0

c       Need to do loop along strike adding up area for all cells with width
c       less than RupWidth

        countnLocX = 0
        do 1234 in2m=1,nfltgrid(2)
          colarea = 0.0
          
C         Check for case in which total area is less than RupArea.
          if (in2m .gt. 1 .and. countnLocX .eq. 0) then
            goto 1233
          endif
          do 1235 in2=in2m,nfltgrid(2)
            colarew = 0.0
            if (in2 .eq. in2m) then
              do iw=1,nfltgrid(1)
                colarew = colarew + fltgrid_w(iw,in2)

C               Find the number of downdip cells for this along strike location to
C               get the correct rupture width.
                if (colarew .gt. rupWidth) then
                  colarew = 0.0
                  goto 2341
                endif
              enddo
 2341         continue
              if (iw .gt. nfltgrid(1) ) iw = nfltgrid(1)
            endif
            
            do 1236 in1=1,iw
              colarea = colarea + fltgrid_a(in1,in2)
              if ( fltgrid_z(in1,in2) .ge. h_listric ) then
                sumArea_deep = sumArea_deep + fltgrid_a(in1,in2)
                if ( in1 .gt. iDD_deep_max ) iDD_deep_max = in1
                if ( in1 .lt. iDD_deep_min ) iDD_deep_min = in1
              else
                sumArea_shallow = sumArea_shallow + fltgrid_a(in1,in2)
                if ( in1 .gt. iDD_shal_max ) iDD_shal_max = in1
                if ( in1 .lt. iDD_shal_min ) iDD_shal_min = in1
              endif
c              write (*,'( 2i5,2f10.3,4i7)') in1, in2, fltgrid_z(in1,in2), h_listric, 
c     1           iDD_shal_min, iDD_shal_max, iDD_deep_min, iDD_deep_max
              
              
 1236       continue
            if (colarea .ge. ruparea) then
              countnLocX = countnLocX + 1
              n1AS(in2m) = nfltgrid(1) - iw + 1
              n2AS(in2m) = in2

              goto 1234
            elseif (in2.eq.nfltgrid(2) .and. colarea.lt.ruparea) then
              goto 1233
            endif

 1235     continue
 1234   continue

 1233   continue
        if (countnLocX .eq. 0) then
          nLocX = 1
          if (sourceType .eq. 1) then
            n1AS(1) = nLocYST1
          else
            n1AS(1) = 1
          endif
            n2AS(1) = nfltgrid(2)
        else
          nLocX = countnLocX
        endif

      endif
      
      if (sumArea_shallow .gt. 0. ) then
        logA_shal = alog10( sumArea_shallow )
      else
        logA_shal = 0.
      endif
      if (sumArea_deep .gt. 0. ) then
        logA_deep = alog10( sumArea_deep )
      else
        logA_deep = 0.
      endif
c      write (*,'( 2f10.2)') sumArea_shallow, sumArea_deep
c      write (*,'( 4i5)') iDD_shal_min, iDD_shal_max, iDD_deep_min, iDD_deep_max
c      pause 'shal_min, shal_max, deep_min, deep_max'
      
      return
      end

c ----------------------------------------------------------------------
       subroutine S28_nLocYcells (iLocX, n1AS, sourceType, nLocX, distDensity, xStep,
     1                        faultWidth, ystep, distDensity2, grid_x, grid_y, x0, y0,
     2                        nLocY, pLocX, r_horiz)
     
       implicit none
       include 'pfrisk.h'

c      declarations passed in
       integer iLocX, n1AS(MAXFLT_AS), sourceType, nLocX
       real distDensity(MAX_DIST1), xStep, faultWidth, ystep, distDensity2(MAX_GRID),
     1      grid_x(MAX_GRID), grid_y(MAX_GRID), x0, y0

c      declarations passed out
       integer nLocY
       real pLocX, r_horiz

              if (sourceType .eq. 1 .or. sourceType .eq. 5 .or. sourceType .eq. 6) then
                nLocY = n1AS(iLocX)
                pLocX = 1./nLocX
              elseif ( sourceType .eq. 2 .or. sourceType .eq. 3 ) then
                pLocX = distDensity(iLocX)               
                if ( pLocX .ne. 0. ) then
                  r_horiz = xStep * (iLocX-0.5)                
                  nLocY = nint(faultWidth / yStep)
                    if (nLocY.eq.0) then
                      nLocY = 1
                    endif
                endif             
              elseif ( sourceType .eq. 4 ) then
                pLocX = distDensity2(iLocX)
                r_horiz = sqrt( (grid_x(iLocX)-x0)**2 + (grid_y(iLocX)-y0)**2 )
                nLocY = nint(faultWidth / yStep)
                  if (nLocY.eq.0) then
                    nLocY = 1
                  endif
              elseif (sourceType .eq. 7) then
                nLocY = 1
                pLocX = 1.0
              endif

       return
       end
