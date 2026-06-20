import React from 'react'
import { Container, Form, Button } from 'react-bootstrap'
function CreateTask() {
  return (
    <Container>
      <h1 className="mb-4">Create New Task</h1>
      <Form>
        <Form.Group className="mb-3">
          <Form.Label>Title</Form.Label>
          <Form.Control type="text" placeholder="Task title" />
        </Form.Group>
        <Form.Group className="mb-3">
          <Form.Label>Description</Form.Label>
          <Form.Control as="textarea" rows={3} />
        </Form.Group>
        <Button variant="primary">Create Task</Button>
      </Form>
    </Container>
  )
}
export default CreateTask
