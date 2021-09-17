clear;

experiment = struct('oil', {}, 'numoil', {}, 'indcode', {}, 'ind', {}, 'numcountry', {});

% load and clean oil futures data
oil_path = "./Data/oil.xlsx";    % oil data
oil_futures = "oil_future";
oil_data = readtable(oil_path, 'Sheet', oil_futures, 'UseExcel', true);
oil_data.date = datetime(oil_data.date, 'InputFormat', 'yyyymmdd');
experiment(1).oil = oil_data;
experiment(1).numoil = size(oil_data, 2) - 1;
disp("Loaded oil data")

ind_code_arr = ["OILGS", "CHMCL", "BRESR", "CNSTM", "INDGS", ...
                "AUTMB", "FDBEV", "PERHH", "HLTHC", "RTAIL", ...
                "MEDIA", "TRLES", "TELFL", "UTILS", "BANKS", ...
                "INSUR", "RLEST", "FINSV", "EQINV", "TECNO"];
experiment(1).indcode = ind_code_arr;

% load and clean industry data
ind_path = "./Data/Industry/Price Index/level3-daily-US dollar.xlsm";    % industrial price index data
ind_data_range = "7:14223";

for ind_code_id = 1:length(ind_code_arr)
    ind_code = ind_code_arr(ind_code_id);
    ind_data = readtable(ind_path, 'Sheet', ind_code, 'UseExcel', true, ...
        'Range', ind_data_range, 'ReadVariableNames', 0, ...
        'TreatAsEmpty', {'NA', ...
        '$$ER: E100,INVALID CODE OR EXPRESSION ENTERED', ...
        '$$ER: E105,INVALID START DATE ENTERED'});
    ind_data.Properties.VariableNames(1) = {'date'};
    experiment(ind_code_id).ind = ind_data;
    experiment(ind_code_id).numcountry = size(ind_data, 2) - 1;
    fprintf("Loaded %s data\n", ind_code)
end

save('./dataset.mat', 'experiment');
