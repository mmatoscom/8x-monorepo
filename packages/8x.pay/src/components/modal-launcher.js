import React, { Component } from 'react';
import SimpleModal from './simple-modal';

import bus from '../bus';

class SimpleModalLauncher extends Component {

  constructor(props) {
    super(props);

    this.state = {
      showModal: false,
    };

    this.listenToggleModal();
  }

  componentWillUnmount() {
    bus.off('modal:show');
  }

  listenToggleModal() {
    bus.on('modal:show',(status) => {
      this.setState({
        showModal: status
      });
    });
  }

  render() {
    const { buttonLabel, children } = this.props;
    const { showModal } = this.state;
    return (
      <div>
        <button
          type="button"
          className='modal-button'
          onClick={() => {
            bus.trigger('modal:show', true);
          }}
        >
          {buttonLabel}
        </button>
        {showModal &&
          <SimpleModal>
            {children}
          </SimpleModal>}
      </div>
    );
  }
}
export default SimpleModalLauncher;