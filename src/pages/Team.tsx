import React from 'react'
import { Container, Card, Button } from 'react-bootstrap'
function Team() {
  return (
    <Container>
      <h1 className="mb-4">Team Members</h1>
      <Card>
        <Card.Body>
          <Card.Title>Team Dashboard</Card.Title>
          <Card.Text>View and manage team members</Card.Text>
        </Card.Body>
      </Card>
    </Container>
  )
}
export default Team
