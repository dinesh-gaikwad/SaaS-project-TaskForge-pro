import React from 'react'
import { Container, Card } from 'react-bootstrap'

function Settings() {
  return (
    <Container>
      <h1 className="mb-4">Settings</h1>
      <Card>
        <Card.Body>
          <Card.Title>Application Settings</Card.Title>
          <Card.Text>Configure your preferences</Card.Text>
        </Card.Body>
      </Card>
    </Container>
  )
}

export default Settings
