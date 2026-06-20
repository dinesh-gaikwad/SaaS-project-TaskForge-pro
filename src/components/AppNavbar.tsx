import React from 'react'
import { Navbar, Nav, Container } from 'react-bootstrap'
import { Link, useLocation } from 'react-router-dom'
function AppNavbar() {
  const location = useLocation()
  return (
    <Navbar bg="primary" variant="dark" expand="lg" className="mb-4">
      <Container>
        <Navbar.Brand as={Link} to="/">TaskForge Pro</Navbar.Brand>
        <Navbar.Toggle aria-controls="basic-navbar-nav" />
        <Navbar.Collapse id="basic-navbar-nav">
          <Nav className="ms-auto">
            <Nav.Link as={Link} to="/" active={location.pathname === '/'}>Home</Nav.Link>
            <Nav.Link as={Link} to="/tasks" active={location.pathname === '/tasks'}>Tasks</Nav.Link>
            <Nav.Link as={Link} to="/team" active={location.pathname === '/team'}>Team</Nav.Link>
            <Nav.Link as={Link} to="/settings" active={location.pathname === '/settings'}>Settings</Nav.Link>
            <Nav.Link as={Link} to="/admin" active={location.pathname === '/admin'}>Admin</Nav.Link>
          </Nav>
        </Navbar.Collapse>
      </Container>
    </Navbar>
  )
}
export default AppNavbar
