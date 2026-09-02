package com.parasoft.parabank.dao.jdbc;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import java.math.BigDecimal;
import java.util.List;

import jakarta.annotation.Resource;

import org.junit.Test;
import org.springframework.test.annotation.Rollback;

import com.parasoft.parabank.dao.LoanRequestDao;
import com.parasoft.parabank.domain.LoanRequestHistory;
import com.parasoft.parabank.test.util.AbstractParaBankDataSourceTest;

@Rollback
public class JdbcLoanRequestDaoTest extends AbstractParaBankDataSourceTest {
    private static final int CUSTOMER_ID = 12212;

    @Resource(name = "loanRequestDao")
    private LoanRequestDao loanRequestDao;

    @Test
    public void testCreateUpdateAndGetLoanRequestsForCustomer() {
        final LoanRequestHistory pendingRequest = createLoanRequest("2026-09-01", "PENDING");
        final LoanRequestHistory completedRequest = createLoanRequest("2026-09-02", "PENDING");
        loanRequestDao.createLoanRequest(pendingRequest);
        loanRequestDao.createLoanRequest(completedRequest);

        completedRequest.setApproved(Boolean.TRUE);
        completedRequest.setResponseDate(convertDate("2026-09-03"));
        completedRequest.setLoanAccountId(Integer.valueOf(12345));
        completedRequest.setProviderName("local");
        completedRequest.setMessage("Approved");
        completedRequest.setStatus("COMPLETED");
        loanRequestDao.updateLoanRequest(completedRequest);

        final List<LoanRequestHistory> requests = loanRequestDao.getLoanRequestsForCustomer(CUSTOMER_ID);

        assertEquals(2, requests.size());
        assertEquals(completedRequest.getId(), requests.get(0).getId());
        assertEquals(Boolean.TRUE, requests.get(0).getApproved());
        assertEquals("local", requests.get(0).getProviderName());
        assertEquals("COMPLETED", requests.get(0).getStatus());
        assertEquals(pendingRequest.getId(), requests.get(1).getId());
        assertNull(requests.get(1).getApproved());
        assertEquals("PENDING", requests.get(1).getStatus());
    }

    private LoanRequestHistory createLoanRequest(final String requestDate, final String status) {
        final LoanRequestHistory loanRequest = new LoanRequestHistory();
        loanRequest.setCustomerId(CUSTOMER_ID);
        loanRequest.setRequestDate(convertDate(requestDate));
        loanRequest.setAvailableFunds(new BigDecimal("1000.00"));
        loanRequest.setLoanAmount(new BigDecimal("5000.00"));
        loanRequest.setDownPayment(new BigDecimal("500.00"));
        loanRequest.setStatus(status);
        return loanRequest;
    }
}