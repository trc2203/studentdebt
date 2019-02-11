% Looped version of my Plan 2 student loan debt prediction tool, applicable for most graduates since 2012
% Intends to demonstrate the effect of starting salary on total amount repaid (assuming growth at a fixed %)
% Written by Tobie Carman www.linkedin.com/in/tobiecarman
% Relatively simplified model, makes the following assumptions:
% > start work in September after graduation (optimistic)
% > constant yearly pay rise (configurable)
% > RPI remains fixed after leaving university (unlikely but impossible to speculate)
% > repayment threshold continues to rise with inflation - set by government - if they are short of cash they may leave it fixed
% > repayment percentage of salary remains constant (likely)
% > debt wiped after 30 years
% Note all money values are relative to year of starting work, i.e. ignoring inflation over the 30 years

%% Adjustable inputs
courseLength = 3; % number of years of undergraduate study
tuition = 9000; % annual undergraduate tuition fee loan in £
maintenance = [3575;3610;3469]; % each year of maintenance loan in £
startPostBal = 10000; % postgraduate loan amount in £ (change to 0 if not taken)
RPI = 0.016; % old rate of inflation (rose from 1.6-3.1% in the last year, may rise further) - this script assumes studying whilst RPI was at the lower value - change to 3.1 if began studying after 2017
salaries = linspace(20000,100000,81);
repaidTotals = [];
amountLeft = [];
outerLoopInd = 1;
for salary = salaries % starting annual salary in £
    threshold = 25000; % repayment salary threshold in £, assumed to rise with inflation (optimistic)
    payRise = 0.02; % annual pay rise above inflation, assumed fixed for simplicity (can be negative)
    fprintf('For a starting salary of £%.2f growing at %g%% per year:\n',salary,payRise*100)

    %% Account for interest accrued during study
    studied = 1;
    undBal = 0;
    while studied<= courseLength
        undBal = (undBal+tuition+maintenance(studied))*(1+RPI); % total undergraduate loan borrowed in £, has been accumulating interest during study
        studied = studied+1;
    end
    RPI = 0.031; % new RPI

    %% Initialise variables
    postBal = startPostBal;
    starttotBal = undBal+postBal;
    totBal = starttotBal;
    month = 0;
    never = 0;
    already = 0;
    duration = 35*12; % attempt to model over 35 year period after graduation, starting in September of first year in work

    %% Pre-allocate arrays for speed
    MONTHS = zeros(1,duration);
    UNDERGRADUATEBALANCE = zeros(1,duration);
    POSTGRADUATEBALANCE = zeros(1,duration);
    BALANCE = zeros(1,duration);
    MONTHLYEARNINGS = zeros(1,duration);
    MONTHLYREPAYMENTS = zeros(1,duration);
    SALARY = zeros(1,duration);
    TOTALREPAID = zeros(1,duration);
    NETREPAYMENTS = zeros(1,duration);

    %% Main loop
    while month<= duration
        if month == 30*12+7 && undBal ~= 0 % loan gets wiped 30 years after April following graduation
            undBal = 0;
            finalTotBal=totBal;
            fprintf('You will never repay your entire student loan. Your starting balance is £%.2f, your remaining balance will be £%.2f, total amount repaid will be £%.2f.\n',starttotBal,totBal,sum(MONTHLYREPAYMENTS))
            never = 1;
        elseif month == 31*12+7
            postBal = 0;
        end
        if salary-threshold>0
            extra = (salary-threshold)*0.0000015; % extra interest paid due to salary
            if extra>0.03 % extra interest capped at 3%
                extra = 0.03;
            end
            undRepay = (salary-threshold)*0.09; % amount paid back per year towards undergraduate debt
            postRepay = (salary-threshold)*0.06; % amount paid back per year towards postgraduate debt
        else
            extra = 0;
            undRepay = 0;
            postRepay = 0;
        end
        if month<7
            undRepay = 0; % won't start paying back until April after graduation
        end
        if month<19
            postRepay = 0; % won't start paying back until April after graduation
        end
        if undBal>undRepay/12
            undBal = undBal-undRepay/12; % monthly repayments
        elseif undBal>0 % Avoids overpayment on final instalment
            undRepay = undBal*12;
            undBal = 0;
        else
            undRepay = 0;
        end
        if postBal>postRepay/12
            postBal = postBal-postRepay/12;
        elseif postBal>0
            postRepay = postBal*12;
            postBal = 0;
            fprintf('You will repay your postgraduate loan after %d years and %d months.\n',fix(month/12),rem(month,12))
        else
            postRepay = 0;
        end
        undIntPc = RPI+extra; % interest percentage
        postIntPc = RPI+0.03; % extra interest flat 3% for postgraduate loan
        if mod(month,12) == 0
            salary = salary*(1+RPI+payRise); % assuming salary rises every year by inflation + x%
            threshold = threshold*(1+RPI);
        end
        undIntPnd = undIntPc*undBal; % how much undergraduate balance will rise by due to interest in £
        postIntPnd = postIntPc*postBal; % how much postgraduate balance will rise by due to interest in £
        undBal = undBal+undIntPnd/12; % accounting for interest after repayments i.e. best case scenario
        postBal = postBal+postIntPnd/12;
        totBal = undBal+postBal;
        month = month+1;
        MONTHS(month) = month;
        UNDERGRADUATEBALANCE(month) = undBal;
        POSTGRADUATEBALANCE(month) = postBal;
        BALANCE(month) = totBal;
        MONTHLYEARNINGS(month) = salary/12;
        MONTHLYREPAYMENTS(month) = (undRepay+postRepay)/12;
        NETREPAYMENTS(month) = (undRepay+postRepay-undIntPnd-postIntPnd)/12;
        if already == 0 && NETREPAYMENTS(month)>0 && month>1
            fprintf('You will be repaying less than the interest your loan is accumulating for the first %d years and %d months.\n',fix(month/12),rem(month,12))
            already = 1;
        end
        SALARY(month) = salary;
        if month ~= 1
            TOTALREPAID(month) = TOTALREPAID(month-1)+MONTHLYREPAYMENTS(month);
        else
            TOTALREPAID(month) = MONTHLYREPAYMENTS(month);
        end
    end

    %% Output results
    [val,ind] = min(BALANCE);
    yearsTaken = fix(MONTHS(ind)/12);
    monthsExtra = rem(MONTHS(ind),12);
    totalRepaid = sum(MONTHLYREPAYMENTS);
    if val<= 0 && never == 0
        fprintf('It will take %d years and %d months to pay off your entire student loan. Your starting balance is £%.2f and total amount repaid will be £%.2f.\n',yearsTaken,monthsExtra,starttotBal,totalRepaid)
        finalTotBal = 0;
    end
    repaidTotals(outerLoopInd) = totalRepaid;
    amountLeft(outerLoopInd) = finalTotBal;
    outerLoopInd = outerLoopInd+1;
end
close all
figure(1)
plot(salaries,repaidTotals)
xlabel('Starting annual salary')
ylabel('Total amount repaid towards student debt over 30 years')
xl=xlim;
set(gca,'XTick', xl(1) : 10000 : xl(2))
yl=ylim;
set(gca,'YTick', yl(1) : 10000 : yl(2))
set(findall(gcf,'-property','FontSize'),'FontSize',18)
grid on
%figure(2)
%plot(salaries, amountLeft)
%xlabel('Starting annual salary')
%ylabel('Amount of student debt left after 30 years')

fprintf("The annual starting salary which repays the most is £%.2f\n",salaries(find(repaidTotals == max(repaidTotals))))
