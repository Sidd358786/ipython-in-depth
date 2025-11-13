#property copyright "Blackbox AI"
#property link      "https://blackbox.ai"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

CTrade trade;

input double StartLot = 0.1;
input double TP_Pips = 0.1;
input double SL_Pips = 0.1;
input string Symbol = "EURUSD";

double currentLot = StartLot;
bool isBuy = true;
ulong lastTicket = 0;

int OnInit() {
    trade.SetExpertMagicNumber(12345); // Optional magic number
    return(INIT_SUCCEEDED);
}

void OnTick() {
    if (PositionsTotal(Symbol) == 0) {
        if (lastTicket != 0) {
            // Position closed, check the reason
            HistorySelect(TimeCurrent() - 86400, TimeCurrent());
            for (int i = HistoryDealsTotal() - 1; i >= 0; i--) {
                ulong ticket = HistoryDealGetTicket(i);
                if (ticket == lastTicket) {
                    double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                    if (profit < 0) {
                        // Loss: reverse direction and double lot
                        isBuy = !isBuy;
                        currentLot *= 2;
                    } else {
                        // Profit: reset to initial
                        isBuy = true;
                        currentLot = StartLot;
                    }
                    break;
                }
            }
            lastTicket = 0;
        }

        // Open new position
        double price = isBuy ? SymbolInfoDouble(Symbol, SYMBOL_ASK) : SymbolInfoDouble(Symbol, SYMBOL_BID);
        double pipMultiplier = (SymbolInfoInteger(Symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(Symbol, SYMBOL_DIGITS) == 3) ? 10 : 1;
        double sl_distance = SL_Pips * pipMultiplier * _Point;
        double tp_distance = TP_Pips * pipMultiplier * _Point;

        double sl = isBuy ? price - sl_distance : price + sl_distance;
        double tp = isBuy ? price + tp_distance : price - tp_distance;

        if (isBuy) {
            trade.Buy(currentLot, Symbol, price, sl, tp);
        } else {
            trade.Sell(currentLot, Symbol, price, sl, tp);
        }

        if (trade.ResultRetcode() == TRADE_RETCODE_DONE) {
            lastTicket = trade.ResultOrder();
        }
    }
}

void OnDeinit(const int reason) {
    // Cleanup if needed
}