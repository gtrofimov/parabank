package com.parasoft.parabank.service;

import java.util.List;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import org.springframework.dao.EmptyResultDataAccessException;

import com.parasoft.parabank.domain.LoanRequestHistory;
import com.parasoft.parabank.domain.logic.BankManager;

@Path("/customers")
@Produces(MediaType.APPLICATION_JSON)
public class LoanRequestHistoryResource {
    private BankManager bankManager;

    @GET
    @Path("/{customerId}/loanRequests")
    @Operation(summary = "Get customer loan request history", tags = { ParaBankServiceConstants.LOANS })
    public Response getLoanRequests(
        @Parameter(required = true) @PathParam("customerId") final int customerId) {
        try {
            if (bankManager.getCustomer(customerId) != null) {
                final List<LoanRequestHistory> loanRequests = bankManager.getLoanRequestsForCustomer(customerId);
                return Response.ok(loanRequests).build();
            }
        } catch (final EmptyResultDataAccessException ex) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.status(Response.Status.NOT_FOUND).build();
    }

    public void setBankManager(final BankManager bankManager) {
        this.bankManager = bankManager;
    }
}