import React                 from "react"
import { Router } from 'react-router'

import AbstractComponent     from "../widgets/abstract-component"

import TextField from "material-ui/TextField"

const keys = new Set([
  "editTarget", "fileNameError"
]);

export default class AgentFileNameField extends AbstractComponent {

  constructor(props) {
    super(props);
    this.state = {
      fileName:      null,
      fileNameError: null
    };
  }

  componentWillMount() {
    const model = this.editor();
    this.registerPropertyChangeListener(model, keys);
    let state = this.collectInitialState(model, keys);
    this.setState(state);
  }

  onPropertyChanged(n, e) {
    if (e.key === "editTarget") {
      this.setState({
        editTarget: e.newValue,
        fileName:   e.newValue ? e.newValue.name : ""
      });
    } else {
      super.onPropertyChanged(n, e);
    }
  }

  render() {
    const errorElement = this.createErrorElement();
    return (
      <TextField
        ref="name"
        hintText="agent.rb"
        floatingLabelText="ファイル名"
        errorText={this.state.fileNameError}
        disabled={!this.state.editTarget}
        onChange={this.onFileNameChanged.bind(this)}
        value={this.state.fileName} />
    );
  }

  createErrorElement() {
    if (this.state.editTarget && this.state.editTarget.status === "error") {
      return this.createErrorContent(this.state.editTarget.error);
    } else {
      return null;
    }
  }

  onFileNameChanged(event) {
    this.setState({fileName: event.target.value});
  }

  get value() {
    return this.state.fileName;
  }

  editor() {
    return this.props.model;
  }
}
AgentFileNameField.propTypes = {
  model: React.PropTypes.object.isRequired
};
AgentFileNameField.contextTypes = {
};
