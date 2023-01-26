/// <reference types="Cypress" />
describe('My First Test', () => {  
  it('Gets value of counter', () => {
	cy.visit(Cypress.env('DEV_URL')),  
    cy.wait(2000)
	cy.visit(Cypress.env('DEV_URL')),
	cy.wait(5000)	
    cy.get('#Counter').then(($counter) => {
      const value = parseInt($counter.text())
	cy.visit(Cypress.env('DEV_URL')), 
    cy.wait(5000)
    cy.get('#Counter').then(($counter2) => {
    const value2 = parseInt($counter2.text())
	expect(value2).to.eq(value + 1)
      })
    })	
  })
})
