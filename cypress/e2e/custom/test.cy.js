/// <reference types="Cypress" />
describe('WebApp Function Test', () => {  

  it('Gets value of counter',
  {
retries:	{
    runMode: 3,
    openMode: 3,
			},
  },
  () => {
	cy.visit(Cypress.env('DEV_URL')), 
	cy.intercept('GET', 'webapp').as('counterRequest')
    cy.wait('@counterRequest').then(($counter) => {
		expect($counter).to.not.be.null
    cy.get('#Counter').then(($counter) => {
      const value = parseInt($counter.text())

	cy.visit(Cypress.env('DEV_URL')), 
	cy.intercept('GET', 'webapp').as('counterRequest')
    cy.wait('@counterRequest').then(($counter2) => {
		expect($counter2).to.not.be.null
    cy.get('#Counter').then(($counter2) => {
      const value2 = parseInt($counter2.text())
	  
	expect(value2).to.eq(value + 1)
      })
    })	
  })
})
})
})