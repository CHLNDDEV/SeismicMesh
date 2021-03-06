classdef edgefx
    %EDGEFX Build a mesh size function gridded interpolant from a velocity
    %       model
    
    %-----------------------------------------------------------
    %   Keith Roberts   : 2019 --
    %   Email           : krober@usp.br
    %   Last updated    : 10/27/2019
    %-----------------------------------------------------------
    %
    
    properties(Access=private)
        wl  % number of nodes given a wave with frequency f 
        f   % maximum frequency of source injection
        hvp % mesh size as a function of seismic p-wavespeed.
        slp % number of nodes per gradient 
        hslp % mesh size as a function of seismic p-wavespeed gradient
        used % edge function keywords
        feat % geodata class instance
        min_el % minimum mesh size (m)
        max_el % maximum mesh size (m)
        g % mesh size gradation rate (decimal percent)
        cr % courant number (unitless)
        dt % desired timestep (s)
        max_sponge_res % max. mesh size in sponge layer
    end
    
    properties(Access=public)
        F % gridded interpolant mesh size function
    end
    
    
    methods(Access=public)
        function obj = edgefx(varargin)
            %
            p = inputParser;
            
            % add name/value pairs
            addOptional(p,'wl',0);
            addOptional(p,'f',0);
            addOptional(p,'slp',0);
            addOptional(p,'min_el',0);
            addOptional(p,'max_el',inf);
            addOptional(p,'g',0);
            addOptional(p,'dt',0);
            addOptional(p,'cr',0);
            addOptional(p,'geodata',0);
            addOptional(p,'max_sponge_res',10e3);

            % parse the inputs
            parse(p,varargin{:});
            % store the inputs as a struct
            inp = p.Results;
            % get the fieldnames of the edge functions
            inp = orderfields(inp,{'geodata','wl','f',...
                                   'slp',...
                                   'min_el','max_el',...
                                   'g','cr','dt',...
                                   'max_sponge_res'});
            flds = fieldnames(inp);
            for i = 1 : numel(flds)
                type = flds{i};
                switch type
                    case('max_sponge_res')
                        obj.max_sponge_res = inp.(flds{i}); 
                        if obj.max_sponge_res~=0 
                            obj.max_sponge_res = inp.(flds{i}); 
                            assert(obj.max_sponge_res > 0); 
                        end
                    case('wl')
                        obj.wl = inp.(flds{i});
                        if obj.wl~=0
                            obj.wl = inp.(flds{i});
                            assert(obj.wl > 0);
                        end
                    case('f')
                        obj.f = inp.(flds{i});
                        if obj.f~=0
                            obj.f = inp.(flds{i});
                            assert(obj.f > 0);
                        end
                    case('slp')
                        obj.slp = inp.(flds{i});
                        if obj.slp~=0
                            obj.slp = inp.(flds{i});
                            assert(obj.slp > 0);
                        end
                    case('min_el')
                        obj.min_el = inp.(flds{i});
                        if obj.min_el~=0
                            obj.min_el = inp.(flds{i});
                            assert(obj.min_el > 0);
                        end
                    case('max_el')
                        obj.max_el = inp.(flds{i});
                        if ~isinf(obj.max_el)
                            obj.max_el = inp.(flds{i});
                            assert(obj.max_el > obj.min_el);
                        end
                    case('geodata')
                        if isa(inp.(flds{i}),'geodata')
                            obj.feat = inp.(flds{i});
                        else
                            error('GEODATA OBJECT REQUIRED');
                        end
                    case('g')
                        obj.g = inp.(flds{i});
                    case('cr')
                        obj.cr = inp.(flds{i}); 
                        if obj.cr~=0
                          assert(obj.cr < 1); 
                        end
                    case('dt')
                        obj.dt = inp.(flds{i});
                        if obj.dt~=0
                          assert(obj.dt > 0);
                          assert(obj.cr > 0); % require cr to be set if dt is set.
                        end
                end
            end
            
            
            % now turn on the edge functions
            for i = 1 : numel(flds)
                type = flds{i};
                switch type
                    case('wl')
                        obj.wl  = inp.(flds{i});
                        if obj.wl(1)~=0
                            disp('Building wavelength function...');
                            obj = wlfx(obj);
                            obj.used{end+1} = 'wl';
                        end
                    case('slp')
                        obj.slp  = inp.(flds{i});
                        if obj.slp(1)~=0
                            disp('Building slope function...');
                            obj = slpfx(obj);
                            obj.used{end+1} = 'slp';
                        end
                end
            end
            
            obj = finalize(obj);
            
        end
        
        
        function plot(obj)
            if obj.feat.GetDim == 2
                [yg,zg]=obj.feat.CreateStructGrid ;
                figure;
                pcolor(zg,yg,obj.F.Values) ;
                shading interp;
                set(gca,'XAxisLocation','top','YAxisLocation','left','ydir','reverse');
                xlabel('X-position (m)');
                ylabel('Z-position/depth (m)');
                cb=colorbar; ylabel(cb,'Desired mesh size (m)') ;
                set(gca,'FontSize',16) ;
                axis equal; axis tight;
            else
                [xg,yg,zg]=obj.feat.CreateStructGrid3D;
                figure; scatter3(xg(:),yg(:),zg(:),5,obj.F.Values(:) ) ;
                set(gca,'XAxisLocation','top','YAxisLocation','left','ydir','reverse');
                xlabel('X-position (m)');
                ylabel('Y-position (m)');
                zlabel('Z-position/depth (m)'); 
                cb=colorbar; ylabel(cb,'Desired mesh size (m)') ;
                set(gca,'FontSize',16) ;
                axis equal; axis tight;
            end
        end
        
        function min_el = GetMinEl(obj); min_el=obj.min_el; end
        
        function max_el = GetMaxEl(obj); max_el=obj.max_el; end 
        
        function feat = GetFeat(obj); feat=obj.feat; end 

    end % end non-static public methods
    
    methods(Access=private)
        
        
        %% Wavelength edgefx.
        function obj = wlfx(obj)
            
            if obj.feat.GetDim == 2
                [yg,zg] = obj.feat.CreateStructGrid;
                Fvp = GetFvp(obj.feat);
                vp = Fvp(yg,zg);
                vp(vp < 0 ) = NaN; 
                obj.hvp=(vp.*obj.f)./obj.wl;
            else
                [xg,yg,zg] = obj.feat.CreateStructGrid3D;
                Fvp = GetFvp(obj.feat);
                vp = Fvp(xg,yg,zg);
                obj.hvp=(vp.*obj.f)./obj.wl;
            end
        end
        %% slope edge function
        function obj = slpfx(obj)
            if obj.feat.GetDim == 2
                [yg,zg] = obj.feat.CreateStructGrid;
                Fvp = GetFvp(obj.feat);
                vp = Fvp(yg,zg);
                vp(vp < 0 ) = NaN; 
                tmp = stdfilter(vp,[3,3],1,'replicate'); % use a larger stencil here for smoother variance
                tmp = real(tmp);
                tmp = (1-tmp./500); %  demoninator is reference gradient for which min_el is mapped
                tmp(tmp > 0.5) = inf; 
                obj.hslp = max(tmp*obj.slp + obj.min_el,10); % ensure result doesn't go negative.
            else
                [xg,yg,zg] = obj.feat.CreateStructGrid3D;
                Fvp = GetFvp(obj.feat);
                vp = Fvp(xg,yg,zg);
                for k = 1 : size(zg,1)
                    tmp = stdfilter(squeeze(vp(k,:,:)),[3,3],1,'replicate'); % use a larger stencil here for smoother variance
                    tmp = real(tmp);
                    tmp = (1-tmp./500); %  demoninator is reference gradient for which min_el is mapped
                    tmp(tmp > 0.5) = 100e3; 
                    obj.hslp(k,:,:) = max(tmp*obj.slp + obj.min_el,10); % ensure result doesn't go negative.
                end
            end
        end

        
        function obj = finalize(obj)
            
            nx = obj.feat.GetNx; 
            ny = obj.feat.GetNy; 
            nz = obj.feat.GetNz; 
            gsp = obj.feat.GetGridspace; 
            dim = obj.feat.GetDim; 
            
            % package the edge functions into a known order.
            counter = 0;
            if dim==2
                hh = zeros([ny,nz,1])+obj.min_el;
            else
                hh = zeros([nx,ny,nz,1])+obj.min_el;
            end
            for i = 1 : numel(obj.used)
                type = obj.used{i};
                switch type
                    case('wl')
                        counter = counter + 1;
                        if dim==2
                            hh(:,:,counter) = obj.hvp;
                        else
                            hh(:,:,:,counter) = obj.hvp;
                        end
                        obj.hvp = single(obj.hvp);
                    case('slp')
                        counter = counter + 1;
                        if dim==2
                            hh(:,:,counter) = obj.hslp;
                        else
                            hh(:,:,:,counter) = obj.hslp;
                        end
                        obj.hslp = single(obj.hslp);
                    otherwise
                        error('FATAL:  Could not finalize edge function');
                end
            end
            
            if dim==2
                [hh_m] = min(hh,[],3);
            else
                [hh_m] = min(hh,[],4);
            end
            clearvars hh
            
             disp('Enforcing size bounds...');
             hh_m(hh_m<obj.min_el)=obj.min_el;
             hh_m(hh_m>obj.max_el)=obj.max_el;
             
             tmp = obj.GetFeat;
             if tmp.expand > 0
                 disp('Building domain extension...');
                 [zg,yg] = obj.feat.CreateStructGrid;
                 tmpFvp = tmp.GetFvp; 
                 tmpvp  = tmpFvp(zg,yg);
                 vp     = tmpvp;
                 border = find(isnan(tmpvp));
                 tmphh_m = hh_m ; 
                 
                 tmphh_m(border)=obj.max_sponge_res; %
%                  
                 hfun = reshape(tmphh_m,[numel(tmphh_m),1]); % reshape column wise
                 if(obj.feat.GetDim==2)
                     dims = int32([size( tmphh_m),1]);
                 else
                     dims = int32(size(tmphh_m));
                 end
                 imax = int32(sqrt(length(hfun)));
                 hfun = FastHJ( dims, gsp, 5.0, imax, int32(1), hfun);
                 if(obj.feat.GetDim==2)
                     tmphh_m = reshape(hfun,[ny,nz]);
                 else
                     tmphh_m = reshape(hfun,[ny,nx,nz]);
                 end
                 clearvars hfun
                 
                 hh_m = tmphh_m; 
                 
                 vp(border) = 1500;                 
                 hfun = reshape(vp,[numel(vp),1]); % reshape column wise
                 if(obj.feat.GetDim==2)
                     dims = int32([size( vp),1]);
                 else
                     dims = int32(size(vp));
                 end
                 imax = int32(sqrt(length(hfun)));
                 hfun = FastHJ( dims, gsp, 0.55, imax, int32(0), hfun);
                 if(obj.feat.GetDim==2)
                     vp = reshape(hfun,[ny,nz]);
                 else
                     vp = reshape(hfun,[ny,nx,nz]);
                 end
                 clearvars hfun
                 
                 % write to disk
                 disp('Writing velocity file to disk...');
                 fid=fopen('Vp_EXTENDED_EXACT.txt','w');
                 vp = flipud(vp);
                 fprintf(fid,'%d,%d\n',size(zg,1),size(zg,2));
                 fprintf(fid,'%f,%f,%f,%f\n',-0.5,17.5,-4.0,0.0);
                 for i = 1 : size(zg,1)
                     fprintf(fid,'%f,',vp(i,1:end-1));
                     fprintf(fid,'%f',vp(i,end));
                     fprintf(fid,'\n') ;
                 end
                 fclose(fid);
                 
                clearvars vp 
                 
             end
             
             if obj.g > 0
                 disp('Relaxing the mesh size gradient...');
                 hfun = reshape(hh_m,[numel(hh_m),1]); % reshape column wise
                 if(obj.feat.GetDim==2)
                     dims = int32([size( hh_m),1]);
                 else
                     dims = int32(size(hh_m));
                 end
                 imax = int32(sqrt(length(hfun))); 
                 hfun = FastHJ( dims, gsp, obj.g, imax, int32(1), hfun);
                 disp('Gradient relaxing converged!');
                 if(obj.feat.GetDim==2)
                     hh_m = reshape(hfun,[ny,nz]);
                 else
                     hh_m = reshape(hfun,[ny,nx,nz]);
                 end
                 clearvars hfun
             end
             
             % enforce the CFL if present
             if obj.dt > 0
                 disp(['Enforcing timestep of ',num2str(obj.dt),' seconds.']);
                 if dim==2
                     [yg,zg] = obj.feat.CreateStructGrid;
                     Fvp = GetFvp(obj.feat);
                     vp = Fvp(yg,zg);
                 else
                     [xg,yg,zg] = obj.feat.CreateStructGrid3D;
                     Fvp = GetFvp(obj.feat);
                     vp = Fvp(xg,yg,zg);
                 end
                 %  vp*dt/dx < cr (generally < 1 for stability).
                 cfl = (obj.dt*vp)./hh_m; % this is your cfl
                 dxn = vp.*obj.dt/obj.cr;      % assume simulation time step of dt sec and cfl of dcfl;
                 hh_m( cfl > obj.cr) = dxn( cfl > obj.cr);   %--in planar metres
                 clear cfl dxn u hh_d;
             end
            
            if dim==2
                [yg,zg]=obj.feat.CreateStructGrid;
                obj.F = griddedInterpolant(yg,zg,hh_m,'linear','nearest');
                clearvars yg zg
            else
                [xg,yg,zg]=obj.feat.CreateStructGrid3D;
                obj.F = griddedInterpolant(xg,yg,zg,hh_m,'linear','nearest');
                clearvars xg yg zg
            end

        end
                
    end % end private non-static methods
end %% end class
    
