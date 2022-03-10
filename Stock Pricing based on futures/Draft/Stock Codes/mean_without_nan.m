function Xmean=mean_without_nan(X)
    if size(X,1)~=1
        num=sum(isfinite(X));
        SX=sum(X,'omitnan');
        Xmean=SX./num;
    else
        Xmean=X;
    end