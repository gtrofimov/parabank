package com.parasoft.parabank.domain;

import java.math.BigDecimal;
import java.util.Date;

public class LoanRequestHistory {
    private int id;
    private int customerId;
    private Date requestDate;
    private BigDecimal availableFunds;
    private BigDecimal loanAmount;
    private BigDecimal downPayment;
    private Boolean approved;
    private Date responseDate;
    private Integer loanAccountId;
    private String providerName;
    private String message;
    private String status;

    public int getId() { return id; }
    public void setId(final int id) { this.id = id; }
    public int getCustomerId() { return customerId; }
    public void setCustomerId(final int customerId) { this.customerId = customerId; }
    public Date getRequestDate() { return requestDate; }
    public void setRequestDate(final Date requestDate) { this.requestDate = requestDate; }
    public BigDecimal getAvailableFunds() { return availableFunds; }
    public void setAvailableFunds(final BigDecimal availableFunds) { this.availableFunds = availableFunds; }
    public BigDecimal getLoanAmount() { return loanAmount; }
    public void setLoanAmount(final BigDecimal loanAmount) { this.loanAmount = loanAmount; }
    public BigDecimal getDownPayment() { return downPayment; }
    public void setDownPayment(final BigDecimal downPayment) { this.downPayment = downPayment; }
    public Boolean getApproved() { return approved; }
    public void setApproved(final Boolean approved) { this.approved = approved; }
    public Date getResponseDate() { return responseDate; }
    public void setResponseDate(final Date responseDate) { this.responseDate = responseDate; }
    public Integer getLoanAccountId() { return loanAccountId; }
    public void setLoanAccountId(final Integer loanAccountId) { this.loanAccountId = loanAccountId; }
    public String getProviderName() { return providerName; }
    public void setProviderName(final String providerName) { this.providerName = providerName; }
    public String getMessage() { return message; }
    public void setMessage(final String message) { this.message = message; }
    public String getStatus() { return status; }
    public void setStatus(final String status) { this.status = status; }
}