import React from 'react'
import { Container, Row, Col, Card, Button } from 'react-bootstrap'

function Tasks() {
  return (
    <Container>
      <h className="mb-4">Tasks</h1>
      <Button variant="primary" href="/tasks/create" className="mb-3">Create New Task</Button>
      <Row>
        <Col md={6}>
          <Card>
            <Card.Body>
              <Card.Title>Sample Task 1</Card.Title>
              <Card.Text>Task description goes here</Card.Text>
              <Button variant="outline-primary" href="/tasks/1">View</Button>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  )
}

export default Tasks
