package com.parasoft.parabank.domain;

import java.math.BigDecimal;
import java.util.Date;

import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
/**
 * Parasoft Jtest UTA: Test class for LoanRequestHistory
 *
 * @see com.parasoft.parabank.domain.LoanRequestHistory
 * @author gtrofimov
 */
public class LoanRequestHistoryTest
{

    /**
     * Parasoft Jtest UTA: Test for getApproved()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getApproved()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetApproved() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Boolean result = underTest.getApproved();

        // Then - assertions for result of method getApproved()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getAvailableFunds()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getAvailableFunds()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetAvailableFunds() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        BigDecimal result = underTest.getAvailableFunds();

        // Then - assertions for result of method getAvailableFunds()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getCustomerId()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getCustomerId()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetCustomerId() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        int result = underTest.getCustomerId();

        // Then - assertions for result of method getCustomerId()
        assertEquals(0, result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getDownPayment()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getDownPayment()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetDownPayment() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        BigDecimal result = underTest.getDownPayment();

        // Then - assertions for result of method getDownPayment()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getId()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getId()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetId() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        int result = underTest.getId();

        // Then - assertions for result of method getId()
        assertEquals(0, result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getLoanAccountId()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getLoanAccountId()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetLoanAccountId() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Integer result = underTest.getLoanAccountId();

        // Then - assertions for result of method getLoanAccountId()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getLoanAmount()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getLoanAmount()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetLoanAmount() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        BigDecimal result = underTest.getLoanAmount();

        // Then - assertions for result of method getLoanAmount()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getMessage()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getMessage()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetMessage() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        String result = underTest.getMessage();

        // Then - assertions for result of method getMessage()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getProviderName()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getProviderName()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetProviderName() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        String result = underTest.getProviderName();

        // Then - assertions for result of method getProviderName()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getRequestDate()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getRequestDate()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetRequestDate() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Date result = underTest.getRequestDate();

        // Then - assertions for result of method getRequestDate()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getResponseDate()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getResponseDate()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetResponseDate() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Date result = underTest.getResponseDate();

        // Then - assertions for result of method getResponseDate()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for getStatus()
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#getStatus()
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testGetStatus() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        String result = underTest.getStatus();

        // Then - assertions for result of method getStatus()
        assertNull(result);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());

    }

    /**
     * Parasoft Jtest UTA: Test for setApproved(Boolean)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setApproved(Boolean)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetApproved() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Boolean approved = false; // UTA: default value
        underTest.setApproved(approved);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNotNull(underTest.getApproved());
        assertFalse(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setAvailableFunds(BigDecimal)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setAvailableFunds(BigDecimal)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetAvailableFunds() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        BigDecimal availableFunds = BigDecimal.ONE; // UTA: default value
        underTest.setAvailableFunds(availableFunds);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNotNull(underTest.getAvailableFunds());
        assertEquals(1d, underTest.getAvailableFunds().doubleValue(), 0.0);
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setCustomerId(int)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setCustomerId(int)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetCustomerId() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        int customerId = 1; // UTA: default value
        underTest.setCustomerId(customerId);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(1, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setDownPayment(BigDecimal)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setDownPayment(BigDecimal)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetDownPayment() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        BigDecimal downPayment = BigDecimal.ONE; // UTA: default value
        underTest.setDownPayment(downPayment);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNotNull(underTest.getDownPayment());
        assertEquals(1d, underTest.getDownPayment().doubleValue(), 0.0);
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setId(int)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setId(int)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetId() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        int id = 1; // UTA: default value
        underTest.setId(id);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(1, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setLoanAccountId(Integer)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setLoanAccountId(Integer)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetLoanAccountId() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Integer loanAccountId = 1; // UTA: default value
        underTest.setLoanAccountId(loanAccountId);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNotNull(underTest.getLoanAccountId());
        assertEquals(1, underTest.getLoanAccountId().intValue());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setLoanAmount(BigDecimal)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setLoanAmount(BigDecimal)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetLoanAmount() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        BigDecimal loanAmount = BigDecimal.ONE; // UTA: default value
        underTest.setLoanAmount(loanAmount);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNotNull(underTest.getLoanAmount());
        assertEquals(1d, underTest.getLoanAmount().doubleValue(), 0.0);
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setMessage(String)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setMessage(String)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetMessage() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        String message = "message"; // UTA: default value
        underTest.setMessage(message);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertEquals("message", underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setProviderName(String)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setProviderName(String)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetProviderName() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        String providerName = "providerName"; // UTA: default value
        underTest.setProviderName(providerName);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertEquals("providerName", underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setRequestDate(Date)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setRequestDate(Date)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetRequestDate() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Date requestDate = new Date(); // UTA: default value
        underTest.setRequestDate(requestDate);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNotNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setResponseDate(Date)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setResponseDate(Date)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetResponseDate() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        Date responseDate = new Date(); // UTA: default value
        underTest.setResponseDate(responseDate);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNotNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertNull(underTest.getStatus());

    }

    /**
     * Parasoft Jtest UTA: Test for setStatus(String)
     *
     * @see com.parasoft.parabank.domain.LoanRequestHistory#setStatus(String)
     * @author gtrofimov
     */
    @Test(timeout = 5000)
    public void testSetStatus() throws Throwable
    {
        // Given
        LoanRequestHistory underTest = new LoanRequestHistory();

        // When
        String status = "status"; // UTA: default value
        underTest.setStatus(status);

        // Then - assertions for this instance of LoanRequestHistory
        assertEquals(0, underTest.getId());
        assertEquals(0, underTest.getCustomerId());
        assertNull(underTest.getRequestDate());
        assertNull(underTest.getAvailableFunds());
        assertNull(underTest.getLoanAmount());
        assertNull(underTest.getDownPayment());
        assertNull(underTest.getApproved());
        assertNull(underTest.getResponseDate());
        assertNull(underTest.getLoanAccountId());
        assertNull(underTest.getProviderName());
        assertNull(underTest.getMessage());
        assertEquals("status", underTest.getStatus());

    }
}
