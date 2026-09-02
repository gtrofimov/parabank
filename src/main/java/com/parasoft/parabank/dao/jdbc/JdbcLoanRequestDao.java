package com.parasoft.parabank.dao.jdbc;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.BeanPropertySqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcDaoSupport;

import com.parasoft.parabank.dao.LoanRequestDao;
import com.parasoft.parabank.domain.LoanRequestHistory;

public class JdbcLoanRequestDao extends NamedParameterJdbcDaoSupport implements LoanRequestDao {
    private static class LoanRequestHistoryMapper implements RowMapper<LoanRequestHistory> {
        @Override
        // parasoft-suppress CWE.352.VPPD "Values are read from the constrained LoanRequest schema."
        // parasoft-suppress CWE.79.VPPD "Values are read from the constrained LoanRequest schema."
        public LoanRequestHistory mapRow(final ResultSet rs, final int rowNum) throws SQLException {
            final LoanRequestHistory loanRequest = new LoanRequestHistory();
            loanRequest.setId(rs.getInt("id"));
            loanRequest.setCustomerId(rs.getInt("customer_id"));
            loanRequest.setRequestDate(rs.getDate("request_date"));
            loanRequest.setAvailableFunds(rs.getBigDecimal("available_funds"));
            loanRequest.setLoanAmount(rs.getBigDecimal("loan_amount"));
            loanRequest.setDownPayment(rs.getBigDecimal("down_payment"));
            loanRequest.setApproved((Boolean) rs.getObject("approved"));
            loanRequest.setResponseDate(rs.getDate("response_date"));
            loanRequest.setLoanAccountId((Integer) rs.getObject("loan_account_id"));
            loanRequest.setProviderName(rs.getString("provider_name"));
            loanRequest.setMessage(rs.getString("message"));
            loanRequest.setStatus(rs.getString("status"));
            return loanRequest;
        }
    }

    private JdbcSequenceDao sequenceDao;

    @Override
    public int createLoanRequest(final LoanRequestHistory loanRequest) {
        final String sql = "INSERT INTO LoanRequest (id, customer_id, request_date, available_funds, loan_amount, down_payment, status) "
            + "VALUES (:id, :customerId, :requestDate, :availableFunds, :loanAmount, :downPayment, :status)";
        final int id = sequenceDao.getNextId("LoanRequest");
        loanRequest.setId(id);
        getNamedParameterJdbcTemplate().update(sql, new BeanPropertySqlParameterSource(loanRequest));
        return id;
    }

    @Override
    public void updateLoanRequest(final LoanRequestHistory loanRequest) {
        final String sql = "UPDATE LoanRequest SET approved = :approved, response_date = :responseDate, loan_account_id = :loanAccountId, "
            + "provider_name = :providerName, message = :message, status = :status WHERE id = :id";
        getNamedParameterJdbcTemplate().update(sql, new BeanPropertySqlParameterSource(loanRequest));
    }

    @Override
    public List<LoanRequestHistory> getLoanRequestsForCustomer(final int customerId) {
        final String sql = "SELECT id, customer_id, request_date, available_funds, loan_amount, down_payment, approved, response_date, "
            + "loan_account_id, provider_name, message, status FROM LoanRequest WHERE customer_id = ? ORDER BY request_date DESC, id DESC";
        return getJdbcTemplate().query(sql, new LoanRequestHistoryMapper(), Integer.valueOf(customerId));
    }

    public void setSequenceDao(final JdbcSequenceDao sequenceDao) {
        this.sequenceDao = sequenceDao;
    }
}