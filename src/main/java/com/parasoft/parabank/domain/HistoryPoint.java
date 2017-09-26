package com.parasoft.parabank.domain;

import java.math.*;
import java.util.*;

import javax.xml.bind.annotation.*;
import javax.xml.bind.annotation.adapters.*;

import com.parasoft.parabank.util.*;

/**
 * Domain object representing a history point
 */
@XmlRootElement(name="historyPoint" , namespace="http://service.parabank.parasoft.com/")
@XmlType(propOrder={"symbol", "date", "closingPrice"})
public class HistoryPoint {
    private String symbol;
    private Date date;
    private BigDecimal closingPrice;

    public String getSymbol() {
        return symbol;
    }

    public void setSymbol(String symbol) {
        this.symbol = symbol;
    }

    @XmlJavaTypeAdapter(DateTimeAdapter.class)
    public Date getDate() {
        return date;
    }

    public void setDate(Date date) {
        this.date = date;
    }

    public BigDecimal getClosingPrice() {
        return closingPrice;
    }

    public void setClosingPrice(BigDecimal closingPrice) {
        this.closingPrice = closingPrice;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + (symbol == null ? 0 : symbol.hashCode());
        result = prime * result + (date == null ? 0 : date.hashCode());
        result = prime * result + (closingPrice == null ? 0 : closingPrice.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof HistoryPoint)) {
            return false;
        }
        HistoryPoint other = (HistoryPoint) obj;
        return Util.equals(symbol, other.symbol) &&
            Util.equals(date, other.date) &&
            Util.equals(closingPrice, other.closingPrice);
    }

    @Override
    public String toString() {
       return "HistoryPoint [symbol=" + symbol + ", date=" + date
           + ", closingPrice=" + closingPrice + "]";
    }
}
