function latexstr = mat2latex(mat, prec)
    % convert the matrix to latex codes
    latexstr = latex(vpa(sym(mat), prec));
