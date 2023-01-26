/// <reference types="Cypress" />
describe('WebApp Function Test', () => {  
  it('Gets value of counter', () => {
	cy.visit(Cypress.env('DEV_URL')),  
    cy.wait(2000)
	cy.visit(Cypress.env('DEV_URL')),
	cy.wait(5000)	
    cy.get('#Counter').then(($counter) => {
      const value = parseInt($counter.text())
	cy.wait(5000)
	cy.visit(Cypress.env('DEV_URL')), 
    cy.wait(5000)
    cy.get('#Counter').then(($counter2) => {
    const value2 = parseInt($counter2.text())
	cy.wait(5000)
	expect(value2).to.eq(value + 1)
      })
    })	
  })
})
