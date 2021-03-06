function y = platform_trajectory_x(t,tf,xf,xcatch,x10,x20,v10,v20,g)

tcatch=...
g.^(-1).*((-1).*v10+(-1).*(v10.^2+(-2).*g.*x10+2.*g.*xcatch).^( ...
  1/2));
b20=...
(-1).*g.*(v10.^2+g.*((-1).*x10+xcatch)+v10.*(v10.^2+2.*g.*((-1).* ...
  x10+xcatch)).^(1/2)).^(-2).*(2.*v10.^4+2.*v10.^3.*((-2).*v20+( ...
  v10.^2+(-2).*g.*x10+2.*g.*xcatch).^(1/2))+v10.^2.*(g.*((-5).*x10+ ...
  3.*x20+2.*xcatch)+(-4).*v20.*(v10.^2+(-2).*g.*x10+2.*g.*xcatch).^( ...
  1/2))+g.*(x10+(-1).*xcatch).*(g.*(2.*x10+(-3).*x20+xcatch)+2.* ...
  v20.*(v10.^2+(-2).*g.*x10+2.*g.*xcatch).^(1/2))+3.*g.*v10.*(2.* ...
  v20.*(x10+(-1).*xcatch)+((-1).*x10+x20).*(v10.^2+(-2).*g.*x10+2.* ...
  g.*xcatch).^(1/2)));
s20=...
3.*g.^2.*(v10+(v10.^2+2.*g.*((-1).*x10+xcatch)).^(1/2)).^(-1).*( ...
  v10.^2+g.*((-1).*x10+xcatch)+v10.*(v10.^2+2.*g.*((-1).*x10+xcatch) ...
  ).^(1/2)).^(-1).*((-1).*v10.^2+2.*g.*(x10+(-1).*x20)+v20.*(v10.^2+ ...
  (-2).*g.*x10+2.*g.*xcatch).^(1/2)+v10.*(v20+(-1).*(v10.^2+(-2).* ...
  g.*x10+2.*g.*xcatch).^(1/2)));
bd0=...
(tcatch+(-1).*tf).^(-3).*(g.*tcatch.*(tcatch.^2+tcatch.*tf+4.* ...
  tf.^2)+4.*tcatch.^2.*v10+tcatch.*(4.*tf.*v10+6.*x10+(-6).*xf)+2.* ...
  tf.*(2.*tf.*v10+3.*x10+(-3).*xf));
sd0=...
(-6).*(tcatch+(-1).*tf).^(-3).*(g.*tcatch.*tf+tcatch.*v10+tf.*v10+ ...
  2.*x10+(-2).*xf);

if t<=tcatch
    y = (1/6).*t.*(3.*b20.*t+s20.*t.^2+6.*v20)+x20;
elseif t>tcatch
    y = (1/6).*(3.*bd0.*(t+(-1).*tcatch).^2+6.*b20.*t.*tcatch+(-3).*b20.* ...
    tcatch.^2+3.*s20.*t.*tcatch.^2+(-2).*s20.*tcatch.^3+sd0.*(t+(-1).* ...
    tcatch).^2.*(t+2.*tcatch)+6.*t.*v20)+x20;
end