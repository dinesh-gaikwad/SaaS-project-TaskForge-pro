import React from 'react'
import { Container, Card } from 'react-bootstrap'

function Admin() {
  return (
    <Container>
      <h1 className="mb-4">Admin Dashboard</h1>
      <Card>
        <Card.Body>
          <Card.Title>Admin Panel</Card.Title>
          <Card.Text>Manage users and system settings</Card.Text>
        </Card.Body>
      </Card>
    </Container>
  )
}

export default Admin
